Overview
The eSewa ePay system enables partner merchants to perform a transaction and receive money from the customer having an eSewa account in a secure environment.

Transaction Flow
1. When user choses eSewa as on-line payment option from partner merchant application, then user is temporarily redirected to eSewa ePay login page.

2. User will provide valid credentials on login page.

3. By confirming the transaction, user is accepting the transaction details sent by partner merchants.

4. After each successful transaction, the user is redirected back to partner merchant's success page. If transaction fails due to any reason (which includes user canceling transaction), the user is informed by appropriate failure message and redirected back to partner merchant's failure page.

5. For every successful transaction, the merchant account is credited accordingly and notified via email/SMS regarding transaction.

6. If a response is not received within five minutes, the status check API can be used to confirm the payment.

7. After receiving a response from the status check API, update the payment status accordingly.

System Interaction
The interactions required to complete a transaction followed by transaction verification process are shown below:


Fig: System interaction for payment with transaction verification process
The scenario visualized in above figure shows an overall communication diagram end to end from merchant to eSewa. In general, merchant sends payment request to eSewa for transaction, where user will login with valid credentials and confirms the transaction. Upon confirmation, user is redirected back to merchant’s success page.

The merchant have to send transaction verification request to eSewa after receiving successful payment for filtering potential fraudulent transactions. The eSewa system will response back accordingly with either success or failure message.

HMAC/SHA256
This HMAC implements the HMAC algorithm as defined in RFC 2104 using the message digest function SHA256. The result MAC value will be a base-64 output type.

Input
Input should be string type and the value of Signed_field_names
Parameters(total_amount,transaction_uuid,product_code) should be mandatory and should be in the same order while creating the signature


total_amount=100,transaction_uuid=11-201-13,product_code=EPAYTEST


SecretKey:
SecretKey for every merchant partner will be provided from eSewa
For UAT, SecretKey will be 8gBm/:&EnhH.1/q( Input should be text type.)

Algorithm used for signature generation is SHA-256
Output:
The generated signature should be in base-64 output type. For eg:

Result

4Ov7pCI1zIOdwtV2BRMUNjz1upIlT/COTxfLhWvVurE=


Examples of creating base64 hashes using HMAC SHA256 in different languages:
JAVASCRIPT
PHP
PYTHON
JAVA
JAVAX
<script src="https://cdnjs.cloudflare.com/ajax/libs/crypto-js/3.1.9-1
/crypto-js.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/crypto-js/3.1.9-1
/hmac-sha256.min.js"></script>
<script src="https://cdnjs.cloudflare.com/ajax/libs/crypto-js/3.1.9-1
/enc-base64.min.js"></script>
<script>
 var hash = CryptoJS.HmacSHA256("Message", "secret");
 var hashInBase64 = CryptoJS.enc.Base64.stringify(hash);
 document.write(hashInBase64);
</script>
 
Integration
During this phase, the merchant will use test user credentials to login in eSewa and process the transaction. Adequate balance will be updated to test the user account.
The partner merchant will send request/post form request with various parameters. Some parameters are mandatory(i.e the parameters must be included) while some are optional.
For end-to-end connection, some safety measures are applied while sending requests. The partner merchant should generate a signature using HMAC algorithm. Here's how the signature is to be generated and the generated signature should be sent along with the other request parameter.

For production please use following url:https://epay.esewa.com.np/api/epay/main/v2/form 

Html
<body>
 <form action="https://rc-epay.esewa.com.np/api/epay/main/v2/form" method="POST">
 <input type="text" id="amount" name="amount" value="100" required>
 <input type="text" id="tax_amount" name="tax_amount" value ="10" required>
 <input type="text" id="total_amount" name="total_amount" value="110" required>
 <input type="text" id="transaction_uuid" name="transaction_uuid" value="241028" required>
 <input type="text" id="product_code" name="product_code" value ="EPAYTEST" required>
 <input type="text" id="product_service_charge" name="product_service_charge" value="0" required>
 <input type="text" id="product_delivery_charge" name="product_delivery_charge" value="0" required>
 <input type="text" id="success_url" name="success_url" value="https://developer.esewa.com.np/success" required>
 <input type="text" id="failure_url" name="failure_url" value="https://developer.esewa.com.np/failure" required>
 <input type="text" id="signed_field_names" name="signed_field_names" value="total_amount,transaction_uuid,product_code" required>
 <input type="text" id="signature" name="signature" value="i94zsd3oXF6ZsSr/kGqT4sSzYQzjj1W/waxjWyRwaME=" required>
 <input value="Submit" type="submit">
 </form>
</body>
 
Demo


form-data:
{
"amount": "100",
"failure_url": "https://developer.esewa.com.np/failure",
"product_delivery_charge": "0",
"product_service_charge": "0",
"product_code": "EPAYTEST",
"signature": "i94zsd3oXF6ZsSr/kGqT4sSzYQzjj1W/waxjWyRwaME=",
"signed_field_names": "total_amount,transaction_uuid,product_code",
"success_url": "https://developer.esewa.com.np/success",
"tax_amount": "10",
"total_amount": "110",
"transaction_uuid": "241028"
}
 
Request Param Details:
Parameter Name	Description
amount
                                            	Amount of product
tax_amount
                                            	Tax amount applied on product
product_service_charge
                                            	product_service_charge Service charge by merchant on product
product_delivery_charge
                                            	Delivery charge by merchant on product
product_code
                                            	Merchant code provided by eSewa
total_amount
                                            	Total payment amount including tax, service and deliver charge. [i.e total_amount= amount+ tax_amount+ product_service_charge + product_delivery_charge ]
transaction_uuid
                                            	A unique ID of product, should be unique on every request.Supports alphanumeric and hyphen(-) only
success_url
                                            	a redirect URL of merchant application where customer will be redirected after SUCCESSFUL transaction
failure_url
                                            	a redirect URL of merchant application where customer will be redirected after FAILURE or PENDING transaction
signed_field_names
                                            	Unique field names to be sent which is used for generating signature
signature
                                            	hmac signature generated through above process.

All parameters are required i.e. values should not be null or empty. If tax_amount, product_service_charge & product_delivery_charge are not used for transaction then their respective values should be zero.
 In transaction_uuid , please use alphanumeric characters and hyphen(-) only


Token
After request is being sent, user is redirected to login page where users input eSewaId and Password. A 6-digit verification token is sent to user mobile(SMS or email) depends upon eSewaId used by user.
For now, only for testing purpose token is 123456 to remove the hassle to obtain token each time after login.

After Successful Payment
After successful payment, the user is redirected to the success URL (that you have sent) along with the response parameters encoded in Base64.
Example (Decoded Response Body):

{
  "transaction_code": "000AWEO",
  "status": "COMPLETE",
  "total_amount": 1000.0,
  "transaction_uuid": "250610-162413",
  "product_code": "EPAYTEST",
  "signed_field_names": "transaction_code,status,total_amount,transaction_uuid,product_code,signed_field_names",
  "signature": "62GcfZTmVkzhtUeh+QJ1AqiJrjoWWGof3U+eTPTZ7fA="
} 
Example (Response Body encoded in Base64)
eyJ0cmFuc2FjdGlvbl9jb2RlIjoiMDAwQVdFTyIsInN0YXR1cyI6IkNPTVBMRVRFIiwidG90YWxfYW1vdW50IjoiMTAwMC4wIiwi
dHJhbNhY3Rpb25fdXVpZCI6IjI1MDYxMC0xNjI0MTMiLCJwcm9kdWN0X2NvZGUiOiJFUEFZVEVTVCIsInNpZ25lZF9maWVsZF9uYW1
lcyI6InRyYW5zYWN0aW9uX2NvZGUsc3RhdHVzLHRvdGFsX2Ftb3VudCx0cmFuc2FjdGlvbl91dWlkLHByb2R1Y3RfY29kZSxzaWd
uZWRfZmllbGRfbmFtZXMiLCJzaWduYXR1cmUiOiI2MkdjZlpUbVZremh0VWVoK1FKMUFxaUpyam9XV0dvZjNVK2VUUFRaN2ZBPSJ9 

Make sure you verify the integrity of the response body by comparing the signature that we have sent with the signature that you generate. Signature should be generated the same way the request’s signature was generated.


Status Check
An API for client enquiry when a transaction is initiated and no response is provided from eSewa or received by Merchant. API parameters are product code, transaction uuid and amount client requests for transaction status with product code , tranasction uuid , total amount,reference id and esewa will respond with successful transaction code and status if failed status only.

Testing Url

https://rc.esewa.com.np/api/epay/transaction/status/?product_code=EPAYTEST&total_amount=100&transaction_uuid=123
 
For Production:

https://epay.esewa.com.np/api/epay/transaction/status/?product_code=EPAYTEST&total_amount=100&transaction_uuid=123
 
Response:
{
  "product_code": "EPAYTEST",
  "transaction_uuid": "123",
  "total_amount": 100.0
  "status": "COMPLETE",
  "ref_id": "0001TS9"
} 
Request Parameter Description and Format
Response Types	Response Description	Response Format
PENDING
                                            	Payment Initiated but not been completed yet	
{
"product_code": "EPAYTEST",
"transaction_uuid": "240508-101430",
"total_amount": 100.0,
"status": "PENDING",
"ref_id": null
}

COMPLETE
                                            	Successful Payment	
{
"product_code": "EPAYTEST",
"transaction_uuid": "240508-10108",
"total_amount": 100.0,
"status": "COMPLETE",
"ref_id": "0007G36"
}

FULL_REFUND
                                            	Full Payment refunded to the customer	
{
"product_code": "EPAYTEST",
"transaction_uuid": "240508-101431",
"total_amount": 100,
"status": "FULL_REFUND",
"ref_id": "0007G36"
}

PARTIAL_REFUND
                                            	Partial payment refunded to the customer	
{
"product_code": "EPAYTEST",
"transaction_uuid": "240508-101431",
"total_amount": 100.0,
"status": "PARTIAL_REFUND",
"ref_id": "0007G36"
}

AMBIGUOUS
                                            	Payment is at hult state	
{
"product_code": "EPAYTEST",
"transaction_uuid": "240508-101431",
"total_amount": 100.0,
"status": "AMBIGUOUS",
"ref_id": "0KDL6NA"
}

NOT_FOUND
                                            	Payment terminated at eSewa: Session expired	
{
"product_code": "EPAYTEST",
"transaction_uuid": "240508-101430",
"total_amount": 100.0,
"status": "NOT_FOUND",
"ref_id": null
}

CANCELED
                                            	Canceled/Reversed from eSewa side	
{
"product_code": "EPAYTEST",
"transaction_uuid": "240508-102939",
"total_amount": 10.0,
"status": "CANCELED",
"ref_id": "0KDL6NA"
}

Service is currently unavailable
                                            	Server connection timeout.	
{
"code": 0,
"error_message": "Service is currently
unavailable"
}

FAQ

What is ePay?

What is the work-flow of eSewa ePay?

What are the item I will get for implementing eSewa ePay API?

Does eSewa provide payment integration in mobile applications?

What is the settlement mechanism from eSewa to Merchant Bank Account?

How eSewa provides support up on receiving any trouble because of ePay?

What is supposed to be done if the payment amount is confirmed by eSewa and transaction amount requested by Web application is not equal?

What is the time per session to make successful payment?

Should customer must have eSewa ID and its credential to do payment ?
Credentials & URLs
Each client will also receive a wallet on eSewa (Merchant wallet) from where they can find payments made for their products/services:

Link For Production Mode: https://merchant.esewa.com.np

To make payment with eSewa sdk. One must be a registered eSewa user. For testing phase, the client/merchant can use the following eSewa id and password:

eSewa ID: 9806800001/2/3/4/5
Password: Nepal@123 MPIN: 1122 (for application only)
Token:123456

