//
//  Value.swift
//  ios
//
//  Created by mac on 2017. 3. 31..
//  Copyright © 2017년 toomics. All rights reserved.
//

import StoreKit

public protocol InappCustomProtocol: NSObjectProtocol {
    // MARK: --- Protocol: SKProductsRequestDelegate 관련 콜백 함수
    // 인앱 상품 정보 수신 후 화면 갱신 시 호출 함수
    func ICproductsRequestSetUI()
    func ICproductsRequestSetUIFinally()
    
    // MARK: --- Protocol: SKPaymentTransactionObserver 관련 콜백 함수
    // 인앱 결제 성공 등 상태에 따른 호출 함수
    func ICpayFail(_ transaction: SKPaymentTransaction)
    
    // MARK: --- Protocol: 영수증 관련 콜백 함수
    func ICreceiptSuccess(_ receipt: String, _ transaction: SKPaymentTransaction, _ isRestore: Bool)
    func ICreceiptFail(_ transaction: SKPaymentTransaction, _ isRestore: Bool)
    
    // MARK: --- Protocol: 복원로직 관련 콜백 함수
    func ICnotEnableRestore()
    func ICrestoreFail(_ error: Error)
    func ICrestoreConsume(_ transaction: SKPaymentTransaction)
}

public class InappCustom: NSObject, SKPaymentTransactionObserver, SKProductsRequestDelegate {
    public weak var delegate: InappCustomProtocol?
    public var request: SKProductsRequest? = nil
    public var inappItem: NSMutableArray? = nil
    private var inappItmeOrder: String = "ASC" // ASC or DESC
    public var restoreItem: NSMutableArray? = nil
    public var isRestoreConsume: Bool = false
    public var restoreTransaction: SKPaymentTransaction? = nil
    weak var viewController: UIViewController? = nil
    
    public init(_ viewC : UIViewController) {
        super.init()
        #if DEBUG
        print("InappCustom ICinappCustom init")
        #endif
        self.viewController = viewC
        
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().add(self)
        }
    }

    deinit {
        #if DEBUG
        print("InappCustom ICinappCustom deinit")
        #endif
        // * 요청 취소
        if self.request != nil {
            self.request?.cancel()
            self.request = nil
        }
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().remove(self)
        }
    }
    
    // MARK: --- Func: InappCustom Class
    public func ICbeforProducts(autofini: Bool) {
        #if DEBUG
        print("InappCustom ICbeforProducts call");
        #endif
        for transactionPending in SKPaymentQueue.default().transactions {
            if transactionPending.transactionState == .purchased || transactionPending.transactionState == .restored {
                #if DEBUG
                print("InappCustom ICinappCustom before transactionPending: \(transactionPending.transactionIdentifier ?? "")");
                print("InappCustom ICbeforProducts transactionPending.transactionIdentifier == \(transactionPending.transactionIdentifier ?? "")")
                print("InappCustom ICbeforProducts transactionPending.transactionDate == \(String(describing: transactionPending.transactionDate))")
                #endif

                self.isRestoreConsume = true
                self.restoreTransaction = transactionPending
                self.delegate?.ICrestoreConsume(transactionPending)

                if autofini {
                    self.ICbeforProductsFiniTransaction(transactionPending)
                }
                break
            }
        }
    }
    
    public func ICbeforProducts(autofini: Bool, _ productSet:Set<String>) {
        #if DEBUG
        print("InappCustom ICbeforProducts call");
        #endif
        for transactionPending in SKPaymentQueue.default().transactions {
            if transactionPending.transactionState == .purchased || transactionPending.transactionState == .restored {
                for product in productSet{
                    #if DEBUG
                    print("InappCustom ICbeforProducts product: \(product)")
                    print("InappCustom ICbeforProducts productIdentifier == \(transactionPending.payment.productIdentifier)")
                    #endif
                
                    if transactionPending.payment.productIdentifier == product {
                        #if DEBUG
                        print("InappCustom ICbeforProducts transactionPending: \(transactionPending.transactionIdentifier ?? "")");
                        print("InappCustom ICbeforProducts transactionPending.transactionIdentifier == \(transactionPending.transactionIdentifier ?? "")")
                        print("InappCustom ICbeforProducts transactionPending.transactionDate == \(String(describing: transactionPending.transactionDate))")
                        #endif

                        self.isRestoreConsume = true
                        self.restoreTransaction = transactionPending
                        self.delegate?.ICrestoreConsume(transactionPending)

                        if autofini {
                            self.ICbeforProductsFiniTransaction(transactionPending)
                        }
                        break
                    }
                }
            }
        }
    }
    
    public func ICbeforProductsFiniTransaction(_ transaction: SKPaymentTransaction) {
        #if DEBUG
        print("InappCustom ICbeforProductsFiniTransaction call");
        #endif
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    public func ICbeforProductsRemoveAll() {
        #if DEBUG
        print("InappCustom ICbeforProductsRemoveAll call");
        #endif
        // 물려있는 내역 삭제
        for transactionPending in SKPaymentQueue.default().transactions {
            if transactionPending.transactionState == .purchased || transactionPending.transactionState == .restored {
                SKPaymentQueue.default().finishTransaction(transactionPending)
            }
        }
    }
    
    // 인앱 상품 정보 가져오기
    public func ICgetProducts(_ productSet: Set<String>, _ inappItmeOrder : String = "ASC") {
        self.inappItmeOrder = inappItmeOrder
        
        if SKPaymentQueue.canMakePayments() {
            self.request = SKProductsRequest(productIdentifiers: productSet)
            self.request?.delegate = self
            self.request?.start()
        } else {
            #if DEBUG
            print("InappCustom ICgetProducts 단말기 결제 가능상태 X")
            #endif
        }
    }
    
    // 인앱 상품 결제 시작
    public func ICstartInAppPay(_ index: Int) {
        let payment = SKPayment(product: (self.inappItem?.object(at: index) as! SKProduct))
        if SKPaymentQueue.canMakePayments() {
            SKPaymentQueue.default().add(payment)
        }
    }
    
    // 영수증 생성 함수
    public func ICgenerateReceipt(transaction: SKPaymentTransaction, isRestore: Bool) {
        do {
            let receiptURL: URL? = Bundle.main.appStoreReceiptURL
            var receipt: Data? = nil
            if let anURL = receiptURL {
                receipt = try Data(contentsOf: anURL)
                if receipt == nil {
                    // 영수증 값이 nil 일 경우
                    SKPaymentQueue.default().finishTransaction(transaction)
                    self.delegate?.ICreceiptFail(transaction, isRestore)
                } else {
                    var encReceipt = receipt?.base64EncodedString(options: [])
                    encReceipt = encReceipt?.replacingOccurrences(of: "+", with: "%2B")
                    #if DEBUG
                    print("InappCustom ICgenerateReceipt encReceipt : \(encReceipt ?? "")")
                    #endif
                    
                    // 영수증 생성이 성공했을 경우
                    if let localReceipt = encReceipt {
                        self.delegate?.ICreceiptSuccess(localReceipt, transaction, isRestore)
                    }
                }
            }
        } catch {
            #if DEBUG
            print("InappCustom ICgenerateReceipt 생성 오류")
            #endif
        }
    }
    
    // 복원 로직 호출 함수
    public func ICcallRestore() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }
    
    // MARK: --- 딜리게이트: SKPaymentTransactionObserver
    public func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        #if DEBUG
        print("InappCustom ICpaymentQueue paymentQueue CALL")
        #endif
        // 복원 상품이 있다면 받을 준비
        self.restoreItem = NSMutableArray.init()
        self.restoreItem?.removeAllObjects()
        
        for transaction in transactions as [SKPaymentTransaction] {
            switch transaction.transactionState {
            case SKPaymentTransactionState.purchased:
                #if DEBUG
                print("InappCustom ICpaymentQueue transaction purchased == \(transaction.transactionIdentifier ?? "")")
                print("InappCustom ICpaymentQueue transaction restored original == \(transaction.original?.transactionIdentifier ?? "")")
                #endif
                // 결제 성공 시 처리 함수 호출
                self.ICgenerateReceipt(transaction: transaction, isRestore: false)
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case SKPaymentTransactionState.failed:
                #if DEBUG
                print("InappCustom ICpaymentQueue transaction failed == \(transaction.transactionIdentifier ?? "")")
                #endif
                delegate?.ICpayFail(transaction)
                SKPaymentQueue.default().finishTransaction(transaction)
                
            case SKPaymentTransactionState.restored:
                #if DEBUG
                print("InappCustom ICpaymentQueue transaction restored == \(transaction.transactionIdentifier ?? "")")
                print("InappCustom ICpaymentQueue transaction restored original == \(transaction.original?.transactionIdentifier ?? "")")
                print("InappCustom ICpaymentQueue transaction restored productIdentifier == \(transaction.payment.productIdentifier )")
                #endif
                self.restoreItem?.add(transaction)
                
            case SKPaymentTransactionState.purchasing:
                #if DEBUG
                print("InappCustom ICpaymentQueue transaction purchasing == \(transaction.transactionIdentifier ?? "")")
                #endif
                
            default:
                break
            }
        }
        
        // * 복원 로직
        if self.restoreItem?.count ?? 0 > 0 {
            var restoreExist : Bool = false
            for i in 0..<(self.restoreItem?.count ?? 0)  {
                if self.inappItem != nil {
                    if self.inappItem?.count ?? 0 > 0 {
                        for j in 0..<(self.inappItem!.count) {
                            let idx = i
                            #if DEBUG
                            print("InappCustom ICpaymentQueue restore index == \(idx)");
                            #endif
                            if let transaction = self.restoreItem?.object(at: idx) as? SKPaymentTransaction {
                                if let product = self.inappItem?.object(at: j) as? SKProduct {
                                    #if DEBUG
                                    print("InappCustom ICpaymentQueue restore productIdentifier1 == \(transaction.payment.productIdentifier)");
                                    print("InappCustom ICpaymentQueue restore productIdentifier2 == \(product.productIdentifier)");
                                    #endif
                                    
                                    if transaction.payment.productIdentifier == product.productIdentifier {
                                        self.ICgenerateReceipt(transaction: transaction, isRestore: true)
                                        SKPaymentQueue.default().finishTransaction(transaction)
                                        restoreExist = true
                                        break
                                    }
                                }
                            }
                        }
                        
                        if restoreExist {
                            break
                        }
                    }
                }
            }
            
            if !restoreExist {
                // 복원 진행 팝업 종료 후 완료 안내 팝업
                self.delegate?.ICnotEnableRestore()
            }
        }
    }
    
    public func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        #if DEBUG
        print("InappCustom ICpaymentQueueRestoreCompletedTransactionsFinished == \(queue.transactions.count)")
        #endif

        // 복원할 내역이 없을 경우
        if queue.transactions.count == 0 {
            // 복원 진행 팝업 종료 후 완료 안내 팝업
            self.delegate?.ICnotEnableRestore()
        } else { // 복원할 내역이 있는 경우
            var restoreEmpty = true // 만료된 트랜젝션 내역에서 복원이 가능한 내역이 있는 지 확인하는 변수
            for transaction in queue.transactions as [SKPaymentTransaction] {
                if transaction.transactionState == .restored {
                    restoreEmpty = false // 만료된 트랜젝션 내역에서 복원가능한 트랜젝션이 있을 경우
                    #if DEBUG
                    print("InappCustom ICpaymentQueueRestoreCompletedTransactionsFinished [restored] transactionIdentifier == \(transaction.transactionIdentifier ?? "")")
                    print("InappCustom ICpaymentQueueRestoreCompletedTransactionsFinished [restored]  transactionIdentifier original == \(transaction.original?.transactionIdentifier ?? "")")
                    print("InappCustom ICpaymentQueueRestoreCompletedTransactionsFinished [restored]  productIdentifier == \(transaction.payment.productIdentifier )")
                    #endif
                    
                    SKPaymentQueue.default().finishTransaction(transaction)
                } else if transaction.transactionState == .purchased {
                    restoreEmpty = false // 만료된 트랜젝션 내역에서 복원가능한 트랜젝션이 있을 경우
                    #if DEBUG
                    print("InappCustom ICpaymentQueueRestoreCompletedTransactionsFinished [purchased]  transactionIdentifier == \(transaction.transactionIdentifier ?? "")")
                    print("InappCustom ICpaymentQueueRestoreCompletedTransactionsFinished [purchased]  transactionIdentifier original == \(transaction.original?.transactionIdentifier ?? "")")
                    print("InappCustom ICpaymentQueueRestoreCompletedTransactionsFinished [purchased]  productIdentifier == \(transaction.payment.productIdentifier )")
                    #endif

                    SKPaymentQueue.default().finishTransaction(transaction)
                }
            }
            
            if restoreEmpty { // 만료된 트랜젝션 내역에서 복원이 가능한 내역이 없다면 프로그래스 종료 되도록 하는 부분
                // 복원 진행 팝업 종료 후 완료 안내 팝업
                self.delegate?.ICnotEnableRestore()
            }
        }
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]) {
        #if DEBUG
        print("InappCustom ICpaymentQueue removedTransactions")
        #endif
    }
    
    public func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        #if DEBUG
        print("InappCustom ICpaymentQueue restoreCompletedTransactionsFailedWithError")
        #endif
        // 복원 진행 팝업 종료 후 복원 실패 팝업 출력
        self.delegate?.ICrestoreFail(error)
    }
    
    // MARK: --- 딜리게이트: SKProductsRequestDelegate
    public func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        var products = response.products
        if self.inappItmeOrder == "DESC" || self.inappItmeOrder == "desc" {
            products = response.products.sorted(by: {$0.price.doubleValue > $1.price.doubleValue})
        } else {
            products = response.products.sorted(by: {$0.price.doubleValue < $1.price.doubleValue})
        }
        
        if products.count != 0 {
            self.inappItem = NSMutableArray.init(capacity: products.count)
            self.inappItem?.removeAllObjects()
            
            for i in 0..<products.count {
                let numberFormatter = NumberFormatter()
                numberFormatter.numberStyle = .currency
                numberFormatter.locale = (products[i] as SKProduct).priceLocale
                let formattedString = numberFormatter.string(from: ((products[i] as SKProduct).price))
                let formattedString2 = numberFormatter.string(from: NSNumber(value: ((products[i] as SKProduct).price.doubleValue)/7))
                #if DEBUG
                print("InappCustom ICproductsRequest 상품 이름 == \((products[i] as SKProduct).localizedTitle )")
                print("InappCustom ICproductsRequest 상품 설명 == \((products[i] as SKProduct).localizedDescription )")
                print("InappCustom ICproductsRequest 상품 가격 1 == \(String(describing: formattedString))")
                print("InappCustom ICproductsRequest 상품 가격 2 == \(String(describing: formattedString2))")
                print("InappCustom ICproductsRequest 상품 가격 3 == \((products[i] as SKProduct).price.doubleValue)")
                print("InappCustom ICproductsRequest 상품 로드 지역 == \((products[i] as SKProduct).priceLocale.currencyCode ?? "")")
                #endif

                self.inappItem?.add(products[i])
            }
            // 불러온 인앱상품을 가지고 UI를 실제로 그리는 부분을 위한 딜리게이트
            self.delegate?.ICproductsRequestSetUI()
        } else {
            #if DEBUG
            print("InappCustom ICproductsRequest 등록된 상품 확인 불가")
            #endif
        }
        
        let productList = response.invalidProductIdentifiers
        for productItem in productList {
            #if DEBUG
            print("InappCustom ICproductsRequest Product not fount : \(productItem)")
            #endif
        }
        // 유효한 상품이 없을때 UI 작업 처리가 필요한 경우
        self.delegate?.ICproductsRequestSetUIFinally()
    }
}
