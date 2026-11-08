# Checkout callable contracts

Call quoteOrder with branchId, deliveryAreaId, deliveryAddress, customerPhone and items. Each item has id and quantity and may include selectedSize, selectedAddons and note. Optional addressId, couponId and tokensRedeemed use the same semantics as placeOrder. The accepted payment method is Cash on Delivery. The response has ok and data, where data contains subtotal, deliveryFee, discount and total in PKR rupees.

Call placeOrder with the same checkout input, a stable requestId and the confirmed total as clientTotal. The server recomputes pricing before commit. A mismatch returns failed-precondition with reason price-changed. Replay of the same request returns the existing order. Legacy branch field names and the placement response are retained for client compatibility. The reference API's marketplace field names, ETA, service fee and tax contract remain pending.

## Server-managed order lifecycle

Call mutateOrder with orderId and action. The transition action accepts status and an optional reason for cancellation. A rider completing an unpaid COD order supplies codCollected after confirming handover and cash collection. The server records the amount from the stored order and commits the receipt with delivery status.

The assign action accepts riderId and the last observed expectedRiderId. The unassign action accepts expectedRiderId. The accept action uses the signed-in rider's identity. The backend checks branch, permissions, assignment state and rider eligibility. The current assignment path allows one active delivery per rider. The audit log and order timeline record each change.

### Allowed transitions

| Actor | Current state | Action and result |
| --- | --- | --- |
| Customer | pending within five minutes | Cancel with a reason |
| Branch order staff or super admin | pending, accepted, preparing | Advance to accepted, preparing, or ready respectively |
| Branch order staff or super admin | any nonterminal state | Cancel with a reason |
| Branch order and rider staff or super admin | ready or assigned before pickup | Assign, replace an unaccepted offer, or unassign back to ready |
| Assigned rider | assigned and awaiting acceptance | Accept the offer or decline and return the order to ready |
| Assigned rider | accepted assignment, picked up, out for delivery | Advance to picked up, out for delivery, or delivered respectively |
| Assigned rider | assigned, picked up, out for delivery | Report failed delivery with a cancellation reason |

A delivery confirmation records unpaid COD once. New offers expire after two minutes. Accept rejects a late offer, and the scheduled job releases expired offers back to Ready without cancelling the order. Previously assigned offers without an expiry remain eligible for acceptance.

The dispatch action finds an eligible online rider for the order branch. For automatic dispatch on Ready, set autoDispatchEnabled to true on the staging branch. Automatic retries stop after three offers. Selection prefers the least recently dispatched rider within a batch of up to 30 online branch riders. Dispatch skips the rider who last declined or timed out. Distance-based dispatch and retries when riders come online are pending.

The settle action records staff confirmation that the rider handed over the full cash amount. Send amountPkr. The server matches it to the original COD receipt, requires branch order and report permissions, and records the actor and time. Repeated confirmation preserves the original settlement.

## Signed public image upload callable

createSignedImageUpload takes purpose and sizeBytes and returns path and token. Supported purposes are product, category, profile and banner. The server chooses the bucket and path, checks the user's profile and applicable branch permissions, and issues at most 60 grants per account per hour. The client uploads the compressed JPEG directly to the assigned path and stores the public image URL.
