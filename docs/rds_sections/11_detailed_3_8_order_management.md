### **3.8 Order Management**

*\[Provide the detailed design for Order Management, covering the barista queue (View Order Queue, Barista Update Status), UC-55 (Request Transaction Refund & Cancellation — cancel PENDING orders by cashier), UC-73 (View Order Detail), UC-75 (SM-Authorized Refund/Comp), plus the system Auto-Abandon of READY orders (a scheduled behavior governed by BR-88, not a numbered UC). Actors: cashier (cancel PENDING only), storemanager (refund/comp authorization + force-close READY at shift close), barista (queue display + status transitions), system scheduler (auto-abandon after `READY_ABANDON_TIMEOUT`). The ORDER statechart documents all 7 valid states and their transitions. Stock model (BR-07/BR-88): stock is deducted only at PREPARING; cancellation is PENDING-only (BR-05), so a cancel never reverses stock.\]*

#### ***3.8.1 Class Diagram***

*\[Class diagram for Order Management. COMET stereotypes: OrderQueueView, BaristaQueueMonitor, CancellationDialog, RefundAuthDialog («boundary»); OrderCoordinator, OrderQueueCoordinator («control»); OrderTimeoutScheduler («timer»); Order, OrderItem, OrderItemTopping, OrderCancellation, OrderRefund («entity»).\]*

```mermaid
classDiagram
    class OrderQueueView {
        <<boundary>>
        +storeId: UUID
        +statusFilter: OrderStatus
        +displayOrders()
    }
    class BaristaQueueMonitor {
        <<boundary>>
        +displayPendingQueue()
        +updateStatus(orderId, status)
    }
    class CancellationDialog {
        <<boundary>>
        +orderId: UUID
        +reason: CancelReason
        +notes: String
        +confirmCancel()
    }
    class RefundAuthDialog {
        <<boundary>>
        +orderId: UUID
        +refundType: RefundType
        +amount: Decimal
        +smApprovalPin: String
        +submitRefund()
    }
    class OrderCoordinator {
        <<control>>
        +getOrderQueue(storeId, filter): List~OrderDto~
        +updateOrderStatus(orderId, newStatus): OrderDto
        +cancelOrder(dto): OrderCancellation
        +authorizeRefund(dto): OrderRefund
    }
    class OrderQueueCoordinator {
        <<control>>
        +getActiveQueue(storeId): List~OrderDto~
        +pushStatusUpdate(orderId, status): void
    }
    class OrderTimeoutScheduler {
        <<timer>>
        +checkInterval: "*/1 * * * *" (every 1 min)
        +readyAbandonTimeout: Duration (READY_ABANDON_TIMEOUT, configurable; default 15 min)
        +scanReadyOrders(): void
        +onTimeout(orderId): void
    }
    class Order {
        <<entity>>
        +id: UUID
        +storeId: UUID
        +shiftSessionId: UUID
        +customerId: UUID
        +voucherId: UUID
        +status: OrderStatus
        +paymentStatus: PaymentStatus
        +paymentMethod: PaymentMethod
        +totalAmount: Decimal
        +notes: String
        +createdAt: DateTime
    }
    class OrderItem {
        <<entity>>
        +id: UUID
        +orderId: UUID
        +menuItemId: UUID
        +quantity: Integer
        +unitPrice: Decimal
    }
    class OrderItemTopping {
        <<entity>>
        +id: UUID
        +orderItemId: UUID
        +toppingId: UUID
        +quantity: Integer
        +unitPrice: Decimal
    }
    class OrderCancellation {
        <<entity>>
        +id: UUID
        +orderId: UUID
        +cashierId: UUID
        +reason: CancelReason
        +notes: String
        +cancelledAt: DateTime
    }
    class OrderRefund {
        <<entity>>
        +id: UUID
        +orderId: UUID
        +smId: UUID
        +cashierId: UUID
        +refundType: RefundType
        +refundAmount: Decimal
        +reason: String
        +authorisedAt: DateTime
    }

    OrderQueueView ..> OrderCoordinator
    BaristaQueueMonitor ..> OrderQueueCoordinator
    CancellationDialog ..> OrderCoordinator
    RefundAuthDialog ..> OrderCoordinator
    OrderTimeoutScheduler --> OrderCoordinator
    OrderCoordinator --> Order
    OrderCoordinator --> OrderItem
    OrderCoordinator --> OrderCancellation
    OrderCoordinator --> OrderRefund
    OrderQueueCoordinator --> Order
    Order *-- OrderItem
    Order *-- OrderCancellation
    Order *-- OrderRefund
    OrderItem *-- OrderItemTopping
```

#### ***3.8.2 UC-55 Request Transaction Refund & Cancellation (Cancel PENDING Order)***

*\[Only PENDING orders can be cancelled by cashier (BR-05). The cancellation creates an immutable OrderCancellation record with the reason code and notes, and the order status transitions to CANCELLED. Cancelled orders cannot be reopened. **No stock action occurs**: in the simplified stock model, stock is deducted only at PREPARING (BR-07), and cancellation is restricted to PENDING — before any deduction — so there is never a stock rollback or replenishment to perform. The cancel flow logs the OrderCancellation only.\]*

```mermaid
sequenceDiagram
    actor cashier
    participant CancelDialog as CancellationDialog
    participant OrderCoord as OrderCoordinator
    participant OrderDB as Order (DB)
    participant CancelDB as OrderCancellation (DB)

    cashier->>CancelDialog: inputCancellationDetails(orderId, reason, notes)
    CancelDialog->>OrderCoord: cancelOrder(dto)
    OrderCoord->>OrderDB: findById(orderId)
    OrderDB-->>OrderCoord: orderRecord
    OrderCoord->>OrderCoord: verifyStatus(order.status == PENDING)
    OrderCoord->>OrderDB: updateStatus(orderId, CANCELLED)
    OrderCoord->>CancelDB: createCancellation(orderId, cashierId, reason, notes, now)
    CancelDB-->>OrderCoord: cancellationRecord
    OrderCoord-->>CancelDialog: showCancellationSuccess()
    CancelDialog-->>cashier: displaySuccess()
```

#### ***3.8.3 UC-75 SM-Authorized Refund / Comp Remake***

*\[For post-PENDING complaints (e.g., wrong order already prepared), only storemanager can authorize a REFUND or COMP_REMAKE. SM enters their PIN to authorize. System creates an immutable OrderRefund record. For COMP_REMAKE type, a new duplicate order is created in PENDING status.\]*

```mermaid
sequenceDiagram
    actor cashier
    actor storemanager
    participant RefundDialog as RefundAuthDialog
    participant OrderCoord as OrderCoordinator
    participant UserDB as User (DB)
    participant OrderDB as Order (DB)
    participant RefundDB as OrderRefund (DB)

    cashier->>RefundDialog: inputRefundDetails(orderId, refundType, amount)
    RefundDialog->>RefundDialog: requestSmPin()
    storemanager->>RefundDialog: inputSmPin(smPin)
    RefundDialog->>OrderCoord: authorizeRefund(dto, smPin)
    OrderCoord->>UserDB: verifySmPin(smId, smPin)
    UserDB-->>OrderCoord: authenticated
    OrderCoord->>OrderDB: findById(orderId)
    OrderDB-->>OrderCoord: orderRecord
    OrderCoord->>RefundDB: createRefund(orderId, smId, cashierId, refundType, amount, reason, now)
    RefundDB-->>OrderCoord: refundRecord

    alt REFUND type
        OrderCoord->>OrderDB: flagRefunded(orderId)
    else COMP_REMAKE type
        OrderCoord->>OrderDB: createNewOrder(cloneOf=orderId, status=PENDING)
    end

    OrderCoord-->>RefundDialog: showRefundSuccess(refundRecord)
    RefundDialog-->>cashier: displaySuccess()
```

#### ***3.8.4 Auto-Abandon READY Orders (OrderTimeoutScheduler — scheduled behavior, BR-88)***

*\[A scheduled behavior, not a numbered use case. READY orders not picked up beyond `READY_ABANDON_TIMEOUT` (configurable; default 15 min) are automatically set to ABANDONED by the OrderTimeoutScheduler. This prevents stale orders from persisting indefinitely in the barista queue. Stock was already deducted at PREPARING (BR-07), so abandonment performs no stock reversal; abandoned orders are reported as uncollected and excluded from net sales (BR-88).\]*

```mermaid
sequenceDiagram
    participant TimeoutScheduler as OrderTimeoutScheduler
    participant OrderCoord as OrderCoordinator
    participant OrderDB as Order (DB)

    loop every 1 minute
        TimeoutScheduler->>OrderDB: findReadyOrdersOlderThan(READY_ABANDON_TIMEOUT)
        OrderDB-->>TimeoutScheduler: expiredOrders[]

        loop for each expiredOrder
            TimeoutScheduler->>OrderCoord: updateOrderStatus(orderId, ABANDONED)
            OrderCoord->>OrderDB: updateStatus(orderId, ABANDONED)
        end
    end
```

#### ***3.8.5 UC-73 View Order Detail***

*\[cashier, storemanager, or barista taps an order to inspect it. The system returns the order header, payment log, and the full item list (each OrderItem plus its selected OrderItemToppings) along with fulfillment status. Read-only — no state transition or stock action occurs.\]*

```mermaid
sequenceDiagram
    actor user as cashier / storemanager / barista
    participant QueueView as OrderQueueView
    participant OrderCoord as OrderCoordinator
    participant OrderDB as Order (DB)

    user->>QueueView: tap order
    QueueView->>OrderCoord: getOrderDetail(orderId)
    OrderCoord->>OrderDB: findByIdWithItems(orderId)
    OrderDB-->>OrderCoord: order + items + toppings + payment log
    OrderCoord-->>QueueView: OrderDetailDto
    QueueView-->>user: display receipt details, payments, fulfillment tracking
```

#### ***3.8.6 ORDER Lifecycle Statechart***

*\[The Order has 7 states. Transitions are enforced by OrderCoordinator. The HOLD state is triggered when a preparation issue is reported by the Barista (reportIssue()). ABANDONED is reached two ways from READY (BR-88): system-triggered after `READY_ABANDON_TIMEOUT` (configurable; default 15 min) in READY state, and Store-Manager force-close of remaining READY orders at shift close. CANCELLED and ABANDONED are terminal states. PENDING → CANCELLED logs the cancellation only; stock is deducted at PREPARING (BR-07), so no transition performs a stock rollback.\]*

```mermaid
stateDiagram-v2
    [*] --> PENDING : submitCheckout() / status = PENDING

    PENDING --> PREPARING : startPreparation() / deductStock(); status = PREPARING

    PENDING --> CANCELLED : cancelOrder(reason) [status == PENDING] / logCancellation(); status = CANCELLED

    PREPARING --> HOLD : reportIssue() / status = HOLD

    PREPARING --> READY : completePreparation() / status = READY

    HOLD --> PREPARING : resolveIssue() / status = PREPARING

    READY --> COMPLETED : confirmPickup() / status = COMPLETED

    READY --> ABANDONED : timeTrigger [elapsedTime >= READY_ABANDON_TIMEOUT] / status = ABANDONED

    READY --> ABANDONED : forceCloseAtShiftClose() [SM authorises, BR-88] / logAbandon(); status = ABANDONED

    COMPLETED --> [*] : archive()
    CANCELLED --> [*] : archive()
    ABANDONED --> [*] : archive()
```

