# Architecture Patterns

实现经过验证的后端架构模式：Clean Architecture、Hexagonal Architecture（端口与适配器）和 Domain-Driven Design（DDD）。用于设计新服务、重构单体、建立限界上下文、调试层间依赖循环。

## When To Load

- 从零设计新后端服务或微服务
- 重构单体应用（业务逻辑与 ORM 模型或 HTTP 关注点纠缠）
- 拆分系统前建立限界上下文
- 调试依赖循环（基础设施代码侵入领域层）
- 创建可测试的代码库（用例测试不需要运行中的数据库）
- 实现 DDD 战术模式（聚合、值对象、领域事件）

## 核心模式

### 1. Clean Architecture（整洁架构）

**层次（依赖向内流动）：**

- **Entities**：核心业务模型，无框架导入
- **Use Cases**：应用业务规则，编排实体
- **Interface Adapters**：控制器、呈现器、网关——在用例与外部格式之间转换
- **Frameworks & Drivers**：UI、数据库、外部服务——全部在最外层

**关键原则：**
- 依赖只向内指向；内层完全不知道外层的存在
- 业务逻辑独立于框架、数据库和交付机制
- 每个层次边界都通过抽象接口跨越
- 无需 UI、数据库或外部服务即可测试

**目录结构：**

```
app/
├── domain/           # 实体、值对象、接口（无实现）
│   ├── entities/     # User, Order
│   ├── value_objects/# Email, Money
│   └── interfaces/   # 抽象端口：IUserRepository, IPaymentGateway
├── use_cases/        # 应用业务规则：CreateUser, ProcessOrder
├── adapters/         # 具体实现
│   ├── repositories/ # PostgresUserRepository
│   ├── controllers/  # UserController
│   └── gateways/     # StripePaymentGateway
└── infrastructure/   # 框架接线、配置、DI 容器
```

**依赖规则一句话：** `domain/` 和 `use_cases/` 中的每个 `import` 只能指向 `domain/`；这两个层次禁止导入 `adapters/` 或 `infrastructure/`。

### 2. Hexagonal Architecture（端口与适配器）

**组件：**

- **Domain Core**：业务逻辑，无框架依赖
- **Ports**：抽象接口，定义核心与外部世界的交互方式（驱动端和被驱动端）
- **Adapters**：端口的具象实现（PostgreSQL 适配器、Stripe 适配器、REST 适配器）

**优势：**
- 无需触碰核心即可替换实现（如 PostgreSQL 换 DynamoDB）
- 测试中使用内存适配器——无需 Docker
- 技术决策推迟到边缘

### 3. Domain-Driven Design（DDD）

**战略模式：**
- **Bounded Contexts（限界上下文）**：为一个子域隔离一致的模型；避免跨系统共享单一模型
- **Context Mapping（上下文映射）**：定义上下文之间的关系（防腐层 ACL、共享内核、开放主机服务）
- **Ubiquitous Language（通用语言）**：代码中的每个术语与领域专家使用的术语一致

**战术模式：**
- **Entities（实体）**：具有稳定标识、随时间变化的对象
- **Value Objects（值对象）**：由属性标识的不可变对象（Email、Money、Address）
- **Aggregates（聚合）**：一致性边界；只有根可从外部访问
- **Repositories（仓储）**：持久化和重建聚合；抽象存储机制
- **Domain Events（领域事件）**：捕获领域内发生的事情；用于跨聚合协调

## 核心实现示例

### 值对象——在构造时验证

```python
@dataclass(frozen=True)
class Email:
    value: str

    def __post_init__(self):
        if "@" not in self.value or "." not in self.value.split("@")[-1]:
            raise ValueError(f"Invalid email: {self.value}")

@dataclass(frozen=True)
class Money:
    amount: int   # 以分为单位
    currency: str

    def __post_init__(self):
        if self.amount < 0:
            raise ValueError("Money amount cannot be negative")
        if self.currency not in {"USD", "EUR", "GBP"}:
            raise ValueError(f"Unsupported currency: {self.currency}")
```

### 用例——编排业务逻辑

用例只依赖抽象端口，不依赖具体实现：

```python
class CreateUserUseCase:
    def __init__(self, user_repository: IUserRepository):
        self.user_repository = user_repository

    async def execute(self, request: CreateUserRequest) -> CreateUserResponse:
        existing = await self.user_repository.find_by_email(request.email)
        if existing:
            return CreateUserResponse(success=False, error="Email already exists")
        user = User(id=str(uuid.uuid4()), email=request.email, name=request.name)
        saved = await self.user_repository.save(user)
        return CreateUserResponse(success=True, user=saved)
```

### 测试——内存适配器

正确应用 Clean Architecture 的标志：每个用例都可以在纯单元测试中测试，无需真实数据库、Docker 或网络：

```python
class InMemoryUserRepository(IUserRepository):
    def __init__(self):
        self._store: dict[str, User] = {}

    async def find_by_email(self, email: str) -> Optional[User]:
        return next((u for u in self._store.values() if u.email == email), None)

    async def save(self, user: User) -> User:
        self._store[user.id] = user
        return user

async def test_create_user_succeeds():
    repo = InMemoryUserRepository()
    use_case = CreateUserUseCase(user_repository=repo)
    response = await use_case.execute(CreateUserRequest(email="alice@example.com", name="Alice"))
    assert response.success
    assert response.user.email == "alice@example.com"
```

## 常见问题与解决

### 用例测试需要运行中的数据库

业务逻辑泄漏到了基础设施层。将所有数据库调用移到 `IRepository` 接口后面，测试中注入内存实现。用例构造函数必须接受抽象端口，而不是具体类。

### 层次间循环导入

常见症状：`use_cases` 和 `adapters` 之间 `ImportError`。当用例导入具体适配器类而不是抽象端口时发生。强制规则：`use_cases/` 只从 `domain/`（实体和接口）导入，绝不从 `adapters/` 或 `infrastructure/` 导入。

### 框架装饰器出现在领域实体中

如果 `@Column()` 或 `@Field()` 出现在领域实体上，实体不再纯粹。在 `adapters/repositories/` 中创建单独的 ORM 模型，在仓储的 `_to_entity()` 方法中做映射。

### 所有逻辑堆积在控制器中

控制器方法只做三件事：解析请求、调用用例、映射响应。一旦超过这些，就将逻辑提取到用例类中。

### 值对象报错太晚

在 `__post_init__` 或构造函数中验证不变性，使无效对象根本无法被构造。这样将错误数据拦截在边界，而不是深层业务逻辑中。

### 限界上下文之间模型泄漏

如果 `Order` 上下文导入了 `Identity` 上下文的 `User` 实体，需要引入防腐层。`Order` 上下文应持有自己的轻量 `CustomerId` 值对象，只通过显式接口调用 `Identity` 上下文。

## 防腐层（Anti-Corruption Layer）

当 `Ordering` 上下文必须从 `Catalog` 上下文获取产品数据时，绝不应直接使用 `Catalog` 的领域模型：

```python
# Ordering 自己的值对象，不是 Catalog 的实体
@dataclass(frozen=True)
class ProductSnapshot:
    sku: str
    name: str
    unit_price: Money
    available: bool

# ACL 适配器：调用 Catalog HTTP API，翻译响应
class CatalogHttpClient(CatalogClientPort):
    async def get_product_snapshot(self, sku: str) -> ProductSnapshot:
        data = await self._http.get(f"{self._base_url}/products/{sku}")
        # 翻译：Catalog 使用 "price_cents"+"currency_code"
        # Ordering 使用 Money(amount, currency)
        return ProductSnapshot(
            sku=data["sku"],
            name=data["title"],
            unit_price=Money(amount=data["price_cents"], currency=data["currency_code"]),
            available=data["stock_count"] > 0,
        )
```

## 上下文映射关系

```
Identity ──Open Host──▶ Ordering (使用 CustomerId VO，非 User entity)
                              │ ACL
                              ▼
                         Catalog Context
Payments ◀──Shared Kernel (Money VO)──▶ Catalog
```

关系类型：Open Host Service（上游提供稳定 API）、ACL（下游翻译上游模型）、Shared Kernel（两个上下文共享小范围子模型）、Conformist（下游原样采用上游模型——最后手段）。

## 聚合设计启发

| 问题 | 指导 |
| ---- | ---- |
| 两个对象是否必须始终一致？ | 放在同一聚合中 |
| 它们可以最终一致吗？ | 放在不同聚合中；用领域事件同步 |
| 是否有一个对象是"所有者"？ | 该对象是聚合根 |
| 删除根是否使子对象无意义？ | 子对象属于聚合内部 |
| 是否为了改一个对象加载了数千个？ | 聚合太大——拆分 |

## 依赖注入接线

所有抽象接口在基础设施层（或 DI 容器）中接线到具体实现。代码库的其他部分不需要知道使用哪个具体类：

```python
# 生产环境
async def get_create_user_use_case() -> CreateUserUseCase:
    pool = await get_db_pool()
    repo = PostgresUserRepository(pool=pool)
    return CreateUserUseCase(user_repository=repo)

# 测试中替换为注入 InMemoryUserRepository —— 无需其他代码更改
```

## 检测和打破依赖循环

| 症状 | 修复 |
| ---- | ---- |
| `use_cases/create.py` 导入了 `adapters/email_sender.py` | 创建 `domain/interfaces/notification_service.py`（抽象端口） |
| `domain/entities/user.py` 导入了 `infrastructure/config.py` | 在基础设施边界将配置值作为构造函数参数传入 |
| 两个聚合互相导入 | 引入领域事件：聚合 A 发出事件，聚合 B 的用例订阅并响应 |
| 仓储导入用例做"额外工作" | 提取额外工作到独立领域服务或用例中 |

## Upstream Tracking

- 原始 Skill 的仓库地址、上游路径和本地镜像目录见 `../../resources/README.md`。
- 上游包含两个子 reference（`details.md`、`advanced-patterns.md`），已在本地镜像中保留：`../../resources/architecture-patterns/references/`。
