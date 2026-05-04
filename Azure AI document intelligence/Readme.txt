resource : oco-invoice-doc-ai

key : <REDACTED>
Endpoint : https://oco-invoice-doc-ai.cognitiveservices.azure.com/

Json path :
InvoiceId : body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['InvoiceId']?['valueString']
InvoiceDate :body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['InvoiceDate']?['valueDate']
DueDate :body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['DueDate']?['valueDate']
VendorAddressRecipient: body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['VendorAddressRecipient']?['valueString']
Subtotal :body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['SubTotal']?['valueCurrency']?['amount']
TotalTax:body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['TotalTax']?['valueCurrency']?['amount']
InvoiceTotal :body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['InvoiceTotal']?['valueCurrency']?['amount']


ColumnPower Automate expression :
InvoiceId:body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['InvoiceId']?['valueString']InvoiceDate:body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['InvoiceDate']?['valueDate']DueDateb:dy('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['DueDate']?['valueDate']VendorName:body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['VendorAddressRecipient']?['valueString']SubTotal:body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['SubTotal']?['valueCurrency']?['amount']TotalTax:body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['TotalTax']?['valueCurrency']?['amount']InvoiceTotal:body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['InvoiceTotal']?['valueCurrency']?['amount']NeedsReviewif(less(body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['InvoiceTotal']?['confidence'], 0.85), true, false)Statusif(less(body('Parse_JSON')?['analyzeResult']?['documents']?[0]?['fields']?['InvoiceTotal']?['confidence'], 0.85), 'Needs Review', 'Pending')