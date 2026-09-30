#ifndef RUNNER_BONJOUR_CHANNEL_H_
#define RUNNER_BONJOUR_CHANNEL_H_

#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/method_channel.h>
#include <windows.h>
#include <windns.h>

#include <memory>
#include <string>

// 局域网发现（V4-M5 mDNS）：电脑广播同步服务，手机按电脑的设备 ID 找回
// 当前地址（电脑换 IP 后不用重新配对）。与 macos/Runner/MainFlutterWindow.swift
// 的 BonjourChannel 保持一致：服务名 `llal-<设备 ID>`，类型 `_llal-sync._tcp`，
// TXT 记录 ips=<逗号分隔的局域网地址>。
//
// 电脑端只广播，不查找（查找是手机的事）。用系统自带的 mDNS
// （DnsServiceRegister，Windows 10 1809 起），不需要另装 Bonjour。
// Dart 侧见 lib/services/sync/lan_discovery.dart。
class BonjourChannel {
 public:
  explicit BonjourChannel(flutter::BinaryMessenger* messenger);
  ~BonjourChannel();

  BonjourChannel(const BonjourChannel&) = delete;
  BonjourChannel& operator=(const BonjourChannel&) = delete;

 private:
  // 成功提交广播返回空字符串，否则返回错误说明。
  std::wstring Publish(const std::wstring& name, int port,
                       const std::wstring& hosts);
  void Unpublish();

  std::unique_ptr<flutter::MethodChannel<flutter::EncodableValue>> channel_;
  PDNS_SERVICE_INSTANCE instance_ = nullptr;
  DNS_SERVICE_REGISTER_REQUEST request_{};
};

#endif  // RUNNER_BONJOUR_CHANNEL_H_
