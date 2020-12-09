# InappCustom

[![CI Status](https://img.shields.io/travis/LimHG/InappCustom.svg?style=flat)](https://travis-ci.org/LimHG/InappCustom)
[![Version](https://img.shields.io/cocoapods/v/InappCustom.svg?style=flat)](https://cocoapods.org/pods/InappCustom)
[![License](https://img.shields.io/cocoapods/l/InappCustom.svg?style=flat)](https://cocoapods.org/pods/InappCustom)
[![Platform](https://img.shields.io/cocoapods/p/InappCustom.svg?style=flat)](https://cocoapods.org/pods/InappCustom)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

InappCustom is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'InappCustom'
```

## How to Use

1. 인앱결제 화면 시작 시 InappCustom 객체 생성 및 초기화
```ruby
// InappCustom Class import
import InappCustom

// InappCustom 변수 선언
var customInapp : InappCustom? = nil

// viewDidLoad 에 InappCustom 변수 초기화 및 InappCustom Delegate 선언
self.customInapp = InappCustom(self)
self.customInapp?.delegate = self

// delegate 선언 시 InappCustomProtocol를 추가 하여야 한다. delegate 함수 정보는 아래에서 확인
class ViewController: UIViewController, InappCustomProtocol {
...
}
```

2. 인앱 상품 정보 불러오기
```ruby
// '상품 공유 ID 1 ~ 4'부분에 등록한 인앱상품 고유 ID를 기입! 노출할 인앱상품 개수만큼 입력 (1개만 입력도 가능)
// ICgetProducts 함수를 통해 Apple Server로 부터 인앱상품 정보를 수신 
// - 기본은 상품 가격을 기준으로 오름차순 정렬이 적용되어 상품 정보를 수신
var productSet:Set<String> = (Set<AnyHashable>(['상품 고유 ID 1', '상품 고유 ID 2', '상품 고유 ID 3', '상품 고유 ID 4']) as? Set<String>)!
if let IC = self.customInapp {
    IC.ICgetProducts(productSet)
}

// - 상품 가격을 기준으로 내림차순 정렬로 변경하려면 "DESC" 적용 (값을 적지 않으면 자동으로 오름차순으로 적용)
IC.ICgetProducts(productSet) 부분을 IC.ICgetProducts(productSet, "DESC") 로 요청


// ICgetProducts 함수를 통해 인앱상품을 수신하여 사용가능한 상품이 존재할 경우 InappCustomProtocol 안 ICproductsRequestSetUI 함수가 호출된다. 
// ICproductsRequestSetUI 호출되는 시점에서 InappCustom Class 안 inappItem Array 변수를 통해 각각의 인앱 상품 정보를 확인할 수 있다.
// Ex) 사용 가능한 인앱 상품 수신 완료
func ICproductsRequestSetUI()
{
    // 수신한 인앱 상품에 접근하는 방법
    // - at: 0 부분에 접근할 상품 인덱스를 기입하여 상품 정보 확인 및 UI 작업 가능
    if let inappProduct = (self.customInapp?.inappItem?.object(at: 0) as! SKProduct) {
        
    }
    // ...
}

// ICgetProducts 함수를 통해 인앱상품을 수신하여 사용가능한 상품이 존재하지 않을 경우에 대한 UI 작업 및 예외처리가 필요할 경우 InappCustomProtocol 안 ICproductsRequestSetUIFinally 함수를 이용한다. 
// ICproductsRequestSetUIFinally 함수는 ICgetProducts 함수를 호출하게 되면 사용가능 상품 정보와 무관하게 호출된다.
// Ex) 사용 가능한 인앱 상품이 없을 경우 예외처리 방법
func ICproductsRequestSetUIFinally()
{
    // 사용가능한 상품이 존재하지 않을 경우
    if(self.customInapp?.inappItem == nil)
    {
    
    }
    // ... 
}
```

3. 인앱 상품 선택 후 결제 프로세스
```ruby
// 결제를 선택한 인앱 상품의 결제 프로세스 시작을 전달하기 위한 함수 인 ICstartInAppPay 함수를 이용
// ICstartInAppPay 함수를 통해 Apple Server로 부터 인앱상품 결제를 시작
if let IC = self.customInapp {
    // 선택한 상품에 대한 인앱결제 시작을 요청
    // - self.customInapp?.inappItem Array 안 몇번째 상품에 대한 결제인지 index 값을 전달한다. 
    // - index: Int 타입으로 전달
    IC.ICstartInAppPay(index)
}

// ICstartInAppPay를 통하여 인앱 결제가 실패가 될 경우 InappCustomProtocol 안 ICpayFail 함수를 이용한다. 
// ICpayFail함수는 결제에 대한 트랜젝션을 파라미터로 전달하여 아래와 같이 에러정보를 확인 할 수 있다. 
// Ex) 사용 가능한 인앱 상품이 없을 경우 예외처리 방법
func ICpayFail(_ transaction: SKPaymentTransaction) {
    if let error = transaction.error as NSError? {
        #if DEBUG
        print("ICpayFail Call = \(error.localizedDescription)")
        #endif
    }
}

// ICstartInAppPay를 통하여 인앱 결제가 성공 될 경우 InappCustom Class 안에서 자동으로 receipt 생성 함수 InappCustomProtocol 안 ICreceiptSuccess 함수를 호출한다.
// ICreceiptSuccess 함수는 생성한 receipt 값과 transaction 그리고 복원 여부의 상태 값을 파라미터로 전달한다. 
// - isRestore 값의 경우 InappCustom의 복원 기능으로 호출하게 될때 true 값이 전달되며, 해당 방법은 아래에서 설명한다.
// - 일반적인 결제 사용에서는 isRestore 값은 false로 전달된다.
// Ex) ICreceiptSuccess 사용 예시
func ICreceiptSuccess(_ receipt: String, _ transaction: SKPaymentTransaction, _ isRestore: Bool)
{
    #if DEBUG
    print("ICreceiptSuccess Call")
    print("ICreceiptSuccess order_id : \(transaction.transactionIdentifier ?? "")")
    print("ICreceiptSuccess order_id_org : \(transaction.original?.transactionIdentifier ?? "")")
    if let aDate = transaction.transactionDate {
        print("ICreceiptSuccess transactionDate : \(aDate)")
    }
    #endif
    
    // 기타 결제 후 인앱상품 지급 처리 로직을 이곳에서 처리한다.
}

// ICreceiptSuccess 함수의 경우 영수증 생성이 성공했을때 호출 되며, 영수증 생성에 실패할 경우 InappCustomProtocol 안 ICreceiptFail 함수를 호출한다.
// ICreceiptFail 함수는 실패한 transaction 그리고 복원 여부의 상태 값을 파라미터로 전달한다. 
// - 복원 여부 상태값을 통하여 일반결제 건 및 복원 건 실패 여부를 구분할 수 있다. 
// Ex) ICreceiptFail 사용 예시
func ICreceiptFail(_ transaction: SKPaymentTransaction, _ isRestore: Bool)
{
    // 결제 실패에 대한 로직 처리를 이곳에서 작성한다.
}
```

4. 구독 상품에 대한 복원 로직 처리
```ruby
// 정기 구독 상품을 이용할 경우 구독 상품에 대한 복원 로직을 구성하여야 한다.
// 앱 안 복원 버튼을 구성한 후 복원 버튼 클릭 시 InappCustom Class 안 ICcallRestore 함수를 통해 Apple Server로 부터 복원 상품에 대한 트랜젝션을 가져온다.
if let IC = self.customInapp {
    IC.ICcallRestore()
}

// 복원할 트랜젝션 없는 경우 InappCustomProtocol 안 ICnotEnableRestore 함수를 호출한다.
// Ex) ICnotEnableRestore 사용 예시
func ICnotEnableRestore()
{
    // 복원할 트랜젝션이 없는 경우 처리는 이곳에서 한다.
}

// 복원할 트랜젝션 있으나 불러오기 실패 시 InappCustomProtocol 안 ICrestoreFail 함수를 호출한다.
// ICrestoreFail 함수의 경우 오류 사항에 대한 Error 파라미터를 전달한다.
// Ex) ICrestoreFail 사용 예시
func ICrestoreFail(_ error: Error)
{
    // 복원 오류에 대한 예외처리를 이곳에서 한다.
}

// 복원할 트랜젝션을 정상적으로 불러오고 복원 로직을 원활하게 수행하게 되면, InappCustom Class 안에서 자동으로 처리되어 InappCustomProtocol 안 ICreceiptSuccess 함수를 호출하며, isRestore 파라미터 값이 true로 전달된다.
```

5. 소모성 상품에 대한 복원 로직 처리
```ruby
// 소모성 상품의 경우 consume 처리가 원활하지 않을 경우 동일한 상품의 재구매가 되지 않도록 설계가 되어 있다. 
// '2. 인앱 상품 정보 불러오기' 전에 purchasing 되어 있는 트랙젝션을 가져와서 결제를 이어갈 수 있도록 추가 설계를 할 수 있다. 
// InappCustom Class 안 ICbeforProducts 함수를 통해 팬딩된 상품 가져오기
// - autofini 값이 true일 경우 재지급 처리와 무관하게 물려있는 트랜젝션을 자동으로 완료처리 한다
// - autofini 값이 false일 경우 재지급 처리 후 ICbeforProductsFiniTransaction(transaction) 함수를 호출해 주어야 완료처리가 된다.
//   단, 물려있는 상품 중 1건에 대해서만 처리가 가능하다, 2건 이상의 경우 물려있는 트랜젝션을 모두 제거한다.
if let IC = self.customInapp {
    IC.ICbeforProducts(autofini: true)
}

// ICbeforProducts 호출 시 purchasing 된 소모성 상품의 트랜젝션이 있으면 InappCustomProtocol 안 ICrestoreConsume 함수를 호출한다.
// ICrestoreConsume 의 경우 purchasing 트랜젝션을 파라미터로 전달한다.
func ICrestoreConsume(_ transaction: SKPaymentTransaction)
{
    // Apple Store 결제는 되었으나 인앱상품 미지급 처리시 호출되며, 미지급에 대한 상품을 지급하도록 이곳에서 처리 한다.
}

// 소모성 상품에 대한 복원 로직 처리를 원하지 않을 경우 ICbeforProductsRemoveAll 함수로 물려있는 트랜젝션을 모두 완료로 처리해준다.
if let IC = self.customInapp {
    IC.ICbeforProductsRemoveAll()
}
```

Protocal. InappCustomProtocol 함수 리스트
```ruby
// InappCustomProtocol 함수 간략 설명
// - SKProductsRequestDelegate를 이용하여 인앱 상품 정보 수신 후 화면 갱신이 필요할때 호출되는 함수 (사용 가능 상품이 있을 경우에만 호출)
func ICproductsRequestSetUI()
// - SKProductsRequestDelegate를 이용하여 인앱 상품 정보 수신 후 화면 갱신이 필요할때 호출되는 함수 (사용 가능 상품 여부와 무관하게 호출)
func ICproductsRequestSetUIFinally()

// MARK: --- Protocol: SKPaymentTransactionObserver 관련 콜백 함수
// 인앱상품 실 결제 로직에서 실패시 호출 함수
func ICpayFail(_ transaction: SKPaymentTransaction)

// MARK: --- Protocol: 영수증 관련 콜백 함수
// 인앱상품 실 결제 성공 후 영수증 생성 성공시 호출 함수
func ICreceiptSuccess(_ receipt: String, _ transaction: SKPaymentTransaction, _ isRestore: Bool)
// 인앱상품 실 결제 성공 후 영수증 생성 실패시 호출 함수
func ICreceiptFail(_ transaction: SKPaymentTransaction, _ isRestore: Bool)

// MARK: --- Protocol: 복원로직 관련 콜백 함수
// 복원할 트랜젝션이 존재하지 않을 경우 호출
func ICnotEnableRestore()
// 복원할 트랜젝션 호출에 실패 시 호출
func ICrestoreFail(_ error: Error)
// 소모성 상품이 소모되지 못한 상태로 존재할 경우 호출되는 함수
func ICrestoreConsume(_ transaction: SKPaymentTransaction)
```


## Author

LimHG, dla.hg210@gmail.com

## License

InappCustom is available under the MIT license. See the LICENSE file for more info.
