#include "bonjour_channel.h"

#include <flutter/standard_method_codec.h>

#include <cwchar>
#include <iterator>
#include <sstream>

#include "utils.h"

namespace {

constexpr wchar_t kServiceSuffix[] = L"._llal-sync._tcp.local";

// 广播结果只写调试输出（与 Mac 端 NSLog 一致）；失败时手机仍可按原地址连接。
VOID WINAPI OnRegisterComplete(DWORD status, PVOID, PDNS_SERVICE_INSTANCE instance) {
  wchar_t line[160];
  swprintf_s(line, L"[bonjour] %ls %ls（状态 %lu）\n",
             status == ERROR_SUCCESS ? L"已广播" : L"广播失败",
             instance && instance->pszInstanceName ? instance->pszInstanceName : L"",
             status);
  ::OutputDebugStringW(line);
  if (instance) {
    ::DnsServiceFreeInstance(instance);
  }
}

// "a.b.c.d" → 网络字节序的 IP4_ADDRESS。
bool ParseIpv4(const std::wstring& text, IP4_ADDRESS* out) {
  unsigned int a, b, c, d;
  wchar_t tail;
  if (swscanf_s(text.c_str(), L"%u.%u.%u.%u%lc", &a, &b, &c, &d, &tail, 1u) != 4 ||
      a > 255 || b > 255 || c > 255 || d > 255) {
    return false;
  }
  *out = a | (b << 8) | (c << 16) | (d << 24);
  return true;
}

// A 记录用的地址：取第一个不是 169.254 链路本地的地址。手机优先读 TXT 里的
// 完整地址列表，这里只是给只看 A 记录的查询方一个能用的值。
bool PickIpv4(const std::wstring& hosts, IP4_ADDRESS* out) {
  std::wstringstream stream(hosts);
  std::wstring host;
  bool found = false;
  while (std::getline(stream, host, L',')) {
    IP4_ADDRESS addr;
    if (!ParseIpv4(host, &addr)) continue;
    if (!found || (*out & 0xFFFF) == 0xFEA9) {  // 已选的是 169.254 就换掉
      *out = addr;
      found = true;
    }
  }
  return found;
}

const flutter::EncodableValue* Arg(const flutter::EncodableMap* args,
                                   const char* key) {
  if (!args) return nullptr;
  auto it = args->find(flutter::EncodableValue(key));
  return it == args->end() ? nullptr : &it->second;
}

}  // namespace

BonjourChannel::BonjourChannel(flutter::BinaryMessenger* messenger)
    : channel_(std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          messenger, "life.long/bonjour",
          &flutter::StandardMethodCodec::GetInstance())) {
  channel_->SetMethodCallHandler([this](const auto& call, auto result) {
    const auto* args = std::get_if<flutter::EncodableMap>(call.arguments());
    if (call.method_name() == "publish") {
      const auto* name = Arg(args, "name");
      const auto* port = Arg(args, "port");
      const auto* hosts = Arg(args, "hosts");
      if (!name || !std::holds_alternative<std::string>(*name) || !port) {
        result->Error("bad_args", "需要 name 和 port");
        return;
      }
      const std::wstring error = Publish(
          Utf16FromUtf8(std::get<std::string>(*name)),
          static_cast<int>(port->LongValue()),
          hosts && std::holds_alternative<std::string>(*hosts)
              ? Utf16FromUtf8(std::get<std::string>(*hosts))
              : std::wstring());
      if (error.empty()) {
        result->Success(flutter::EncodableValue(true));
      } else {
        result->Error("publish_failed", Utf8FromUtf16(error.c_str()));
      }
    } else if (call.method_name() == "unpublish") {
      Unpublish();
      result->Success(flutter::EncodableValue(true));
    } else {
      // resolve 只在手机上用。
      result->NotImplemented();
    }
  });
}

BonjourChannel::~BonjourChannel() {
  Unpublish();
}

std::wstring BonjourChannel::Publish(const std::wstring& name, int port,
                                     const std::wstring& hosts) {
  Unpublish();

  wchar_t computer[MAX_COMPUTERNAME_LENGTH + 64];
  DWORD size = static_cast<DWORD>(std::size(computer));
  if (!::GetComputerNameExW(ComputerNameDnsHostname, computer, &size)) {
    return L"取不到本机名";
  }
  const std::wstring host_name = std::wstring(computer) + L".local";
  const std::wstring instance_name = name + kServiceSuffix;

  IP4_ADDRESS ip4 = 0;
  const bool has_ip4 = PickIpv4(hosts, &ip4);
  PCWSTR keys[] = {L"ips"};
  PCWSTR values[] = {hosts.c_str()};
  instance_ = ::DnsServiceConstructInstance(
      instance_name.c_str(), host_name.c_str(), has_ip4 ? &ip4 : nullptr,
      nullptr, static_cast<WORD>(port), 0, 0, hosts.empty() ? 0 : 1, keys,
      values);
  if (!instance_) {
    return L"构造广播记录失败";
  }

  request_ = {};
  request_.Version = DNS_QUERY_REQUEST_VERSION1;
  request_.InterfaceIndex = 0;  // 所有网卡
  request_.pServiceInstance = instance_;
  request_.pRegisterCompletionCallback = OnRegisterComplete;
  request_.pQueryContext = nullptr;
  request_.hCredentials = nullptr;
  request_.unicastEnabled = FALSE;
  const DWORD status = ::DnsServiceRegister(&request_, nullptr);
  if (status != DNS_REQUEST_PENDING) {
    ::DnsServiceFreeInstance(instance_);
    instance_ = nullptr;
    return L"DnsServiceRegister 返回 " + std::to_wstring(status);
  }
  return std::wstring();
}

void BonjourChannel::Unpublish() {
  if (!instance_) return;
  ::DnsServiceDeRegister(&request_, nullptr);
  ::DnsServiceFreeInstance(instance_);
  instance_ = nullptr;
}
