---

## id: full_managed_product_requirements_v1_0

title: 全托管产品需求文档
last_updated: 2026-07-02
last_verified_at: 2026-07-02
confidence: draft

# 全托管产品需求文档/Full-Managed Product Requirements

> **Contributors**: chaoyue.wang ｜ **最后更新**：2026-07-01 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/sub-kb/2.6-advertiser-strategy/full-managed-product-requirements_v1.0.md)

## 1. 定位/Positioning

全托管 Agent 是卖家授权下的广告投放经理，负责理解目标、管理广告、持续调优、解释结果。

## 2. 阶段目标/Phase Goals


| 阶段                   | 目标      | 验收重点（week 1-2 ）                                                  | 验收重点（week 3-4 ）                                                            |
| -------------------- | ------- | ---------------------------------------------------------------- | -------------------------------------------------------------------------- |
| Phase 1（7月）：SAS 试点   | 跑通全托管闭环 | Dev开发，包括全链路打通、量效兑换模型等                                            | 【Week 4】7.24 全链路上线：1-2个真实卖家，加入全托管实验中，确保全链路稳定（基建正常、实时调控、调控记录、调控解释、不突破安全边界） |
| Phase 2（8月）：SAS 试点   | 全托管效果调优 | 【Week1】20个SAS试点卖家，By shop 效果回收、动作Review；【Week2】扩大放量，沉淀策略建议，效果迭代； | 【Week 3】扩大放量，沉淀策略建议，效果迭代【Week 4】Overall 效果回收，达成北极星指标（Agent 调控正向率>80 %）     |
| Phase 3（9月）：GMS 高渗卖家 | 白盒上线扩量  | 全托管白盒化产品上线                                                      | GMS 高渗卖家升级切换                                                               |


Phase 1-2 不承诺预算增长或收入提升，重点是效率提升、无明显负向、可解释、可被卖家信任。

## 3. 成功指标/Success Metrics

Phase 2 

- 北极星指标：SAS卖家30日托管效果正向率，预期不低于80%
  - 正向定义：托管前 vs 托管期间，托管卖家 vs 大盘卖家，Shop plat GMV 持平/上涨，且Shop Total ROI达标（>=卖家ROI约束）
- 中间指标：托管前 vs 托管期间，托管卖家 ROI、Campaign 达标率、Campaign 空耗率、预算使用率、新品占比 无明显负向
- 红线指标：突破安全边界 Bad case 率 （= bad case / Total test seller ）严控不高于5%

Phase 3 

- success metrics 暂不在本文详细展开，未来会包括 
  - 大盘 TR提升（通过预算提升撬动Rev提升，前提是效果起码打平卖家自主调控）、Adoption、商家满意度 / 留存，效果层面不做个性化策略达成的细拆



## 4. 目标用户/Target Sellers

以下用户逐层筛选，分批引入测试

- SAS 试点 Seller ：有运营跟进，便于收集目标、边界和 case 反馈；
- 意向度：AI 接纳度高，托管意向度高，托管边界宽（允许系统调整商品 & TROI & 预算 & 启停）；
- 店铺画像：中腰部 / 成长型、多 SKU
- 投广画像：已在投广、投广目标和系统大方向一致、有一些个性化要求、投广有调优空间（E.g. 单品低预算高空耗、单日频繁调整TROI、启停广告）

重要：和Local 确认合作方式，Phase 1-2 卖家不感知是 人工 or 全托管agent 来为他调整广告

节奏：本周内 确认 Phase 1-2 参与卖家 LIst、合作方式

## 5. Seller 托管要求输入/Seller Managed Requirements Input


| 输入   | 默认要求                        | Phase 1-2 个性化要求                        |
| ---- | --------------------------- | -------------------------------------- |
| 投放目标 | 提高 Shop Plat GMV            | Phase 1-2 不支持其他目标                      |
| 商品约束 | Shop Total SKU              | 支持排除商品 ，维度包括单商品 / L2-L3 品类             |
| 预算约束 | 托管周期内 30日 总预算（要求 >= 人工投放预算） | 支持设置单商品 / L2-L3 品类 / 新品 单独预算 / 天级别单独预算 |
| 效果约束 | Shop Broad ROI（要求不高于人工投放目标） | 支持设置单商品 / L2-L3 品类 / 新品 单独ROI约束        |
| 托管周期 | 30天                         | /                                      |


> > Todo：Phase 1-2 Google sheet 确定列明，给到dev ，Phase 3 可拓展更多维度，支持规则形式调整，确定规则依赖的信息（比如价格带）

Highlight：

- 以上要求（尤其是效果约束）均对齐托管卖家对 Local 人工操作的要求，全托管产品的使命是在目标一致的前提下优于人工操作效果 / 效果打平效率更优；
- ROI 效果赔付机制：Campaign Level ROI 超收问题走自动赔付流程，若Shop Level ROI <= 70% * 卖家要求，走额外赔付（排除自动赔付部分）；>> 待与ops local align （offline支持）
- 超预算赔付：如果实际花费超出卖家约定全托管预算，可进行赔付；>> 待与ops local align （offline支持）



## 6. 授权边界/Authorization Boundaries

以下为系统不可突破的安全硬边界，需要按照卖家允许的方式 自动执行 / 人工确认 / 不允许，一期建议先按照如下：


| 动作类别                                       | 自动执行 / 人工确认 / 不允许 |
| ------------------------------------------ | ----------------- |
| 新建 / 暂停 / 重启广告                             | 默认自动执行            |
| 预算增加 / 降低                                  | 默认自动执行            |
| TROI 增加 / 降低                               | 默认自动执行            |
| 商品增加 / 排除                                  | 默认自动执行            |
| 工具使用（E.g. Campaign Surge、ABI、Rapid Boost ) | 不允许               |
| 充值相关                                       | 不允许               |


Todo：补充一列，每个动作下系统层面（排除卖家输入外）不可突破的硬约束：

- 新建 / 暂停 / 重启：不能大范围重启 等
- 预算：当日预算不超过多少，
- TROI：不低于xx，

人工确认流程：

- Phase 1 - Phase 2 ：系统产出动作 List ，天级别与SAS Local 确认（为降低测试成本，可优先找不需要人工确认的商家测试）；
- Phase 3：托管期间卖家登陆平台时提示， 同时 Weekly Report 提示（需要保证实效性，均为当前最新的确认建议）；



## 7. 策略能力/Required Strategy Capabilities

7.1 整体能力

- 在满足卖家全托管投广约束（效果 / 预算 / 商品）的情况下，在托管周期内，达成卖家全店托管目标；
- 不突破卖家授权边界的情况下，对广告（单品 / 多品 / GMS  ✖️ Simple / Target ）进行操作调优；
- **核心操作能力：选品、组品（用什么广告类型PT支持）、预算分配、TROI（单值/range）调整、出价模式（troi / troi range / 纯 BCB）**
  - 待建设能力：组品
  - PM提供 可以提供一些业务信息输入，不作为硬规则
    - 比如基本逻辑是：多品组合 参考相同category，相同价格带，相同利润空间，如果差异化较大的，爆品 / 成长品单独用单品，剩余长尾品打包给GMS


| 卖家画像 | 场景 / 商品生命周期        | 广告产品         |
| ---- | ------------------ | ------------ |
| 头腰卖家 | 爆品 / 成长品           | 单品 / 多品（为主）  |
|      | 测品（长尾非新品 / 新品）/ 清仓 | 多品 / GMS     |
| 小微卖家 | 成长品                | 单品 / 多品      |
|      | 测品（长尾非新品 / 新品）/ 清仓 | 多品 / GMS（为主） |
|      |                    |              |


7.2 场景化能力

- 大促策略
  - 支持天级别预算分配：
    - 目标：以托管30日内Shop整体托管预算为总约束，保持大促期间有较为充足的预算
    - 大促定义：Follow Campaign surge 大促定义；
    - 预算策略：
      - 店铺天预算软Cap：
        - 初始值：大促期间，根据预估 Plat gmv 增幅分配 1.x BAU预算（100元），剩余BAU均分
          - Todo：分析一下追加预算的卖家，campaign active hours vs BAU active houres 是否接近，如果接近，代表卖家追加预算合理
        - 大促预算策略：（100元）分3笔预算，根据大促流量峰值，比如xx点前一笔，xx-xx点 一笔；
- 支持大促期间更敏捷的调整
  - BAU 天级别调整，熔断小时级；>> 当前考虑更实时的调整不一定正向，先按照天级别调整，后续可以视情况优化；
  - 大促缩短一日多次 （分析：BAU VS 大促 卖家实际调整 广告启停 / TROI / 预算的频次）
- Todo：ROI 熔断机制（实时触发）-- 模拟投手盯盘，条件 * 预期动作
  - Campaign / Shop 不同维度，ROI 低于xx，熔断
  - 预算花费 xx % & 空耗 
  - 时间：至少xx触发一次
- 新品策略
  - 新品范围：默认系统新品（商品上架30天）定义；
  - 新品预算：如卖家未单独表达，默认GMS选品新品策略（当前大预算 10% 新品预算），支持新品单独预算进行探索、默认承接新品扶持能力；
  - 新品目标：如卖家未单独表达，默认系统 Follow 当前破零率目标；
- 卖家个性化策略 （根据调研结论，一期需要系统支持）
  - 支持卖家个性化设定单个商品 / L2 - L3类目 / 个性化定义（含 策略组定义 / 覆盖商品 / 目标 / 预算 / ROI ），系统需完成策略组目标；
  - Todo：分析卖家设定 L2/L3 类目TROI设置差异化情况

7.3 灵活性能力

- 卖家投广要求变更：允许卖家托管周期内，有限次调整投广要求（包括 目标 / 约束 / 周期），比如：sellers有一笔新的托管预算、ROI要提高至xx 、更新可投商品范围等；
  - Phase 1-2 调整需 offline 人工通知至PM和dev，天级别更新；
  - Phase 3 白盒化产品能力承接，小时级更新；



## 8. 卖家交互/Seller Interaction Requirements



### 8.1 Phase 1-2 SAS 测试阶段/Test Stage

测试阶段Ops & Local 线下传达为主，不要求完整线上卖家交互。


| 场景                           | 线下传达方式                                    | 需要传达的信息                     |
| ---------------------------- | ----------------------------------------- | --------------------------- |
| 开启前 - 信息收集确认 （本周内）           | Ops & SAS Local 确认托管List                  | 托管卖家名单、托管要求                 |
| 实验中 - 系统操作产出                 | 系统产出天级别操作清单，PM 人工后置Review 动作合理性           | 做了什么、为什么做、是否越界、效果如何-- 详见9   |
| 实验中 - 异常 / 高风险动作确认（非必要）-- 备选 | 系统天级别产出待确认动作，SAS Local 每日单独确认，确认前系统不得擅自操作 | 预算异常、ROI风险、商品风险、动作超出常规边界。   |
| 实验中 - Local 日常反馈             | SAS Local 汇总给 PM / 研发 确认                  | 是否有异常 / 不合理问题、是否要调整目标/商品/预算 |
| 周度 / 双周复盘                    | Weekly Report 同步至SAS Local                | 本周效果、关键动作、风险、下周计划、待确认事项     |




### 8.2 Phase 3 白盒上线阶段/White-Box Launch Stage --  平台PRD另出

Phase 3 需要逐步从线下传达切到线上白盒化披露，需要确认白盒化产品入口、托管计划、托管状态、Weekly Report。

- 托管前：和卖家确认托管计划，包括
  - 本轮目标、预算、ROI 底线、托管商品、排除商品、禁止动作、自动执行动作、需确认动作、风险提示（卖家预期管理）、利益点展示。卖家确认前，不进入自动执行；
  - 卖家确认后，在托管周期内可有限次调整以上信息；
- 托管中，卖家需随时看到：
  - 托管状态：当前是否在托管中、当前设置的托管要求；
  - 托管现状：当前投广商品、广告类型、预算、ROI（及当前平台全部可披露的效果指标）
  - 待确认动作
- Weekly Report
  - 本周效果、表现好/不好的地方，和目标差距；
  - 本周核心动作、为什么做、效果如何、还有哪些待确认动作；
  - 下周计划继续做什么、调整什么、有什么风险；



### 9 可追溯信息要求/Traceable Information Requirements

两个核心目的：

- 人工 review 策略合理性，判断系统动作是否符合卖家目标、约束和授权边界。
- 给卖家做白盒化披露，让卖家理解系统做了什么、为什么做、结果如何。

产出物：

- PM效果Review方式：优先找效果不达标的Shop，Review Shop Action & Reason，如果有和目标不一致的异常行为，分析调优；
- 以下为PM propose，实际Reason由dev提供，不会包括决策点 / 动作目标这种信息；


| 信息                | 要求                                                                     |
| ----------------- | ---------------------------------------------------------------------- |
| 卖家目标              | 目标、预算、ROI、商品范围、托管周期、授权边界（包括中途调整信息）                                     |
| 决策原因 & 上下文 reason | 决策点（ ROI超收 / 预算受限 / ... ）、明细数据（决策前 店铺、商品、广告状态，效果等）                     |
| 动作依据 Reason       | 动作目标（ ROI修复 / 放量 / ... ）、决策依据（调用量效预估模型 / xx规则决策）、决策置信度、预估影响（xx动作可带来xx） |
| 动作记录 Acton        | 做了什么、作用对象、执行时间、执行前后变化、自动执行/人工确认/阻断状态                                   |
| 动作效果（后验效果回收）      | 是否有效（对Shop整体目标达成的影响、单次行动是否达成预估效果）；明细数据（动作后的GMV、ROI、预算使用、空耗/超收 等）       |
|                   |                                                                        |










**【0707会议纪要】**@Luka Yang @Zhenlin Du @Peng Jiacheng @Feifei @Zhao Licheng 赵立铖｜Ads Platform PM @Fengyi Yang | Product Ads PM 

**已和dev对齐 Phase 1-2 全托管整体产品需求、核心策略能力、测试方案；**

Next Step：

- PM：@chaoyue 补充今日会上讨论的规则细节，周四 和 dev 二次沟通对齐，主要包括：
  - Phase 1-2 卖家要求 Google sheet 确定具体列名
  - 系统动作硬约束规则（E.g. TROI不低于xx) 
  - 组品：业务信息输入
  - 预算：大促店铺总日预算下，3笔预算分配策略；
  - ROI 熔断机制
- Dev：@Zhenlin Du 预计本周四 TD Review 









### 9 参考/Reference

- BR Agente Ads 访谈纪要

[https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/team/10.paid-ads-pm/10.trd-prd-td-list/2026q2/o101/kr1-kp1-202606181817/resource/agente-ads-brazil-interview-2026-06-30.md](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/team/10.paid-ads-pm/10.trd-prd-td-list/2026q2/o101/kr1-kp1-202606181817/resource/agente-ads-brazil-interview-2026-06-30.md)

- SAS Local Program 调研

[https://docs.google.com/document/d/1OTpgwxvm6GL7lRIeTkSN3oGF0Q4BTMJ7/edit](https://docs.google.com/document/d/1OTpgwxvm6GL7lRIeTkSN3oGF0Q4BTMJ7/edit)

- CB 投广调研

[https://docs.google.com/document/d/163OBHJq0ZUttELvXktueHmNMBrZJIryggSVLx5if1Fc/edit?tab=t.m610a57u04js#heading=h.j903374noie](https://docs.google.com/document/d/163OBHJq0ZUttELvXktueHmNMBrZJIryggSVLx5if1Fc/edit?tab=t.m610a57u04js#heading=h.j903374noie)