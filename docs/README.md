# 设计文档索引

本目录说明项目当前的需求、设计与实现状态。项目根目录的 [README.md](../README.md) 是面向使用者的产品介绍和构建说明。

| 文档 | 内容 |
|---|---|
| [requirements.md](requirements.md) | 产品需求（R 编号） |
| [decisions.md](decisions.md) | 设计决策及理由（D 编号） |
| [product-spec.md](product-spec.md) | 功能范围、页面与交互、验收场景（A 编号） |
| [schema.md](schema.md) | 数据模型：实体、字段、状态、时间语义、同步 |
| [prompts.md](prompts.md) | 发给模型的全部提示词与输入范围 |
| [platform-matrix.md](platform-matrix.md) | 各平台能力的实现与验证状态（P 编号） |
| [plan-android.md](plan-android.md) | 安卓端适配计划与进度 |
| [development.md](development.md) | 开发说明：工程约定、主要依赖、平台技术要点与已知问题 |

## 编号约定

- `R-xx`：需求，定义在 `requirements.md`；
- `D-xx`：设计决策，定义在 `decisions.md`；
- `A-xx`：验收场景，定义在 `product-spec.md`；
- `P-xx`：平台能力项，定义在 `platform-matrix.md`。

代码注释用这些编号指向对应的设计说明。编号不复用，因此会有空号。

## 维护规则

- 文档只描述当前状态，不保留修订记录；变更历史以 git 提交为准。
- 改数据结构前先改 `schema.md`；改提示词时同步改 `prompts.md`。
- `platform-matrix.md` 只凭实际验证结果更新状态。
- 功能变化时同步修改根目录的 README。
