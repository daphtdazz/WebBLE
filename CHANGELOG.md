# 1.7.1

- Switch to using `WKScriptMessageHandlerWithReply` for request / response transactions from 
  javascript to swift allowing for general tidy-up of transaction handling. Means can only support
  iOS 14+ but that's OK since it's 2026 now and setting min deployment to 15.6
