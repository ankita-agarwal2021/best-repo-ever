global class OrdPay_PIS_Generation_Batch implements Database.Batchable<sObject>,Database.Stateful
{
    public decimal CashAmount;
    public decimal ChequeAmount;
    public decimal totaldenomAmount;
    public decimal totalAmount;
    public decimal totalcashAmount;
    public decimal totalchequeAmount;
    public Boolean errorflag;
    public String regionIDn = 'a0S280000028XmD';
    public List<attachment> lstattch;
    
    global OrdPay_PIS_Generation_Batch()
    {
        System.debug('Class calling');
        CashAmount = 0;
        ChequeAmount = 0;
        totaldenomAmount = 0;
        totalAmount = 0;
        totalcashAmount = 0;
        totalchequeAmount = 0;       
    }
    
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        System.debug('start ==> ');
        String query ='';
        Date d = date.newInstance(2018, 8, 30);        
        System.debug('d =======> ' + d);
        
        if(Test.isrunningTest())
        {
            query ='select id,name,Amount_Recived__c,Account_Name__r.RecordType.Name,Amount__c,Payment_Mode__c,CreatedDate,Payment_Status__c,PIS_Number__c,Receipt_No__c,Amount_Collected_By_1__c,Is_PIS_Genrated__c,Account_Name__r.name,Account_Name__c ,Account_Name__r.CKSW__ShippingRegion__c ,Account_Name__r.CKSW__ShippingRegion__r.name, Account_Name__r.Service_Center__r.Code__c from Order_payment__c where  Payment_Status__c=\'Accepted\' AND CreatedDate <= TODAY  AND (Payment_Mode__c =\'Cash\' OR Payment_Mode__c =\'Cheque\') AND Is_PIS_Genrated__c = False Order By Amount_Collected_By_1__c DESC,CreatedDate DESC';
        }
        else
        {
            query ='select id,name,Amount_Recived__c,Account_Name__r.RecordType.Name,Amount__c,Collect_from_SC__r.Code__c,Payment_Mode__c,CreatedDate,Payment_Status__c,PIS_Number__c,Receipt_No__c,Amount_Collected_By_1__c,Is_PIS_Genrated__c,Account_Name__r.name,Account_Name__c ,Account_Name__r.CKSW__ShippingRegion__c ,Account_Name__r.CKSW__ShippingRegion__r.name, Account_Name__r.Service_Center__r.Code__c from Order_payment__c where  Payment_Status__c=\'Accepted\' AND CreatedDate <= TODAY  AND (Payment_Mode__c =\'Cash\' OR Payment_Mode__c =\'Cheque\') AND Is_PIS_Genrated__c = False   AND (collect_from_SC__c != null OR Account_Name__r.Service_Center__c != null)  Order By Amount_Collected_By_1__c DESC,CreatedDate DESC';
            //query ='select id,name,Amount_Recived__c,Account_Name__r.RecordType.Name,Amount__c,Payment_Mode__c,CreatedDate,Payment_Status__c,PIS_Number__c,Receipt_No__c,Amount_Collected_By_1__c,Is_PIS_Genrated__c,Account_Name__r.name,Account_Name__c ,Account_Name__r.CKSW__ShippingRegion__c ,Account_Name__r.CKSW__ShippingRegion__r.name, Account_Name__r.Service_Center__r.Code__c from Order_payment__c where  Payment_Status__c=\'Accepted\' AND CreatedDate <= TODAY  AND (Payment_Mode__c =\'Cash\' OR Payment_Mode__c =\'Cheque\') AND Is_PIS_Genrated__c = False  Order By Amount_Collected_By_1__c DESC,CreatedDate DESC';
        }
        return Database.getQueryLocator(query);
    }
    
    
    global void execute(Database.BatchableContext BC, List<Order_Payment__c> opList)
    {
        Pay_In_Slip__c objofPIS = new Pay_In_Slip__c();
        List<Pay_In_Slip__c> lstOfPISToInsert = new List<Pay_In_Slip__c>();
        Map<String,Order_payment__c> UpdateOp = new Map<String,Order_payment__c>();
        List<Order_Payment__c> opListGenPDFUpdate = new List<Order_Payment__c>();
        pageReference ref;                
        Map<String, List<Order_payment__c>> mapofOP = new Map<String,List<Order_payment__c>>();   
        Map<String,String> jsonMap = new Map<String,String>();
        Map<String, Pay_In_Slip__c> mapofPISTOInsert = new Map<String,Pay_In_Slip__c>();        
        lstattch = new List<attachment>();
        for(Order_payment__c opay : opList)
        {            
            List<Order_Payment__c> ordpaylist;
            String scCode = '';
            if(opay.Account_Name__r.RecordType.Name == 'Bill To'){
                scCode = opay.Collect_from_SC__r.Code__c;
            }
            else{
                scCode = opay.Account_Name__r.Service_Center__r.Code__c;
            }
            
            if(mapofOP.containsKey(scCode))
            {                
                mapofOP.get(scCode).add(opay);                
            }
            else
            {
                ordpaylist = new List<Order_Payment__c>();
                ordpaylist.add(opay);
                mapofOP.put(scCode,ordpaylist);               
            }                                
        }
        System.debug('mapofOP =====> ' + mapofOP);
        
        for(String key :mapofOP.keySet()){
            String serviceCenter = '';
            for(Order_Payment__c opObj : mapofOP.get(key))
            {
                serviceCenter = opObj.Account_Name__r.Service_Center__c;
                
                if(opObj.Amount_Recived__c == null){
                    opObj.Amount_Recived__c = 0; 
                }
                if(opObj.Payment_Mode__c == 'Cash'){
                    CashAmount += opObj.Amount_Recived__c;
                }
                
                if(opObj.Payment_Mode__c == 'Cheque'){
                    ChequeAmount += opObj.Amount_Recived__c;
                }
            }
            
            objofPIS = new Pay_In_Slip__c();
            objofPIS.Service_Center__c  = serviceCenter;
            objofPIS.Date__c = System.Today();
            objofPIS.Customer_Code__c = 'Hicare' ;
            objofPIS.Total_Cash_Amount__c = CashAmount; 
            objofPIS.Total_Cheque_Amount__c= ChequeAmount;
            objofPIS.Total_Denomination_Amount__c = CashAmount;
            objofPIS.Total_Amount__c =  objofPIS.Total_Cash_Amount__c +  objofPIS.Total_Cheque_Amount__c;
            
            String strTest = String.valueof(objofPIS.Total_Cash_Amount__c).trim();
            
            List<String> arrTest= strTest.split('\\.');
            System.debug('res====>'+arrTest);
            
            System.debug('arrTest ===>'+arrTest);
            
            jsonMap.put('type','writer');
            /* jsonMap.put('coins',String.valueof(objofPIS.X1_Paisa__c).trim());
jsonMap.put('1',String.valueof(objofPIS.X1_X__c).trim());
jsonMap.put('2',String.valueof(objofPIS.X2_X__c).trim());
jsonMap.put('5',String.valueof(objofPIS.X5_X__c).trim());
jsonMap.put('10',String.valueof(objofPIS.X10_X__c).trim());
jsonMap.put('20',String.valueof(objofPIS.X20_X__c).trim());
jsonMap.put('50',String.valueof(objofPIS.X50_X__c).trim());
jsonMap.put('100',String.valueof(objofPIS.X100_X__c).trim());
jsonMap.put('200',String.valueof(objofPIS.X200_X__c).trim());
jsonMap.put('500',String.valueof(objofPIS.X500_X__c).trim());
jsonMap.put('2000',String.valueof(objofPIS.X2000_X__c ).trim());*/
            jsonMap.put('NetAmount',arrTest[0]);
            jsonMap.put('BankdepositSlipNo',objofPIS.Deposit_Slip_No_Of_Cash__c);
            jsonMap.put('StopId',objofPIS.Stop_Id__c);
            jsonMap.put('HierarchyCode',objofPIS.Hirarchy_Code__c);
            jsonMap.put('CustCode',objofPIS.Stop_Id__c);
            jsonMap.put('AccountNo','HICARE');
            
            String mapJson =(String) JSON.Serialize(jsonMap);
            
            System.debug('Map Con Json==>'+JSON.Serialize(jsonMap));
            System.debug('sampleJson data\"y==='+mapJson);
            String qrcode='https://chart.apis.google.com/chart?chs=150x150&cht=qr&chl='+ mapJson;
            
            objofPIS.QR_Code__c='<img src='+qrcode + '></img>';               
            
            mapofPISTOInsert.put(key,objofPIS);
        }
        
        
        insert mapofPISTOInsert.values();
        /* Set<Id> pisid = new Set<Id>();
for(Pay_In_Slip__c objPis : mapofPISTOInsert.values())
{

}*/
        
        for(String key : mapofPISTOInsert.keySet()){
            if(mapofOP.containsKey(key)){
                for(Order_payment__c ordpay : mapofOP.get(key)){
                    Order_payment__c  opay = new Order_payment__c();
                    opay.id = ordpay.id;
                    opay.Pay_In_Slip__c = mapofPISTOInsert.get(key).Id;
                    //opay.Is_PIS_Genrated__c = true;
                    UpdateOp.put(opay.id,opay);
                }
            }
        }
        
        System.debug('UpdateOp====>'+UpdateOp);
        
        if(UpdateOp.size()>0)
        {
            update UpdateOp.values();
        }
        
        for(Pay_In_Slip__c objPis: mapofPISTOInsert.values())
        {
           /* if(objPis!=null)
            {
                Pay_In_Slip__c  payObj = [select id,name,ChequeDepositeNo__c,CashDepositeNo__c from Pay_In_Slip__c where id=: objPis.id];
                Integer year =  Integer.valueOf(String.valueOf(Date.Today().Year()).right(2));                
                objPis.Deposit_Slip_No_Of_Cash__c = System.Today().DAY()+''+System.Today().Month()+''+year +''+payObj.CashDepositeNo__c ;
                System.debug('objPis.Deposit_Slip_No_Of_Cash__c ======> ' + objPis.Deposit_Slip_No_Of_Cash__c);
                objPis.Deposit_Slip_No_Of_Cheque__c  = System.Today().DAY()+''+System.Today().Month()+''+year +''+payObj.ChequeDepositeNo__c;
                System.debug('objPis.Deposit_Slip_No_Of_Cheque__c ======> ' + objPis.Deposit_Slip_No_Of_Cheque__c);
                //update objPis;
            }*/
            
            System.debug('objPis.id =======> ' + objPis.id);
            
            /*Blob body;
            PageReference pdf = Page.PIS_GenerationVFPage;
            pdf.getParameters().put('id',objPis.Id);
               try {
                body = pdf.getContentAsPDF();
            } 
            catch (VisualforceException e) {
                body = Blob.valueOf('Some Text');
            }               
                  Attachment at = new Attachment();
                  at.Name = 'PIS1';
                  at.Body=body;
                  at.ParentId = objPis.Id;
                  at.contentType = 'application/pdf';
                  lstattch.add(at);            
        }
        
        if(lstattch.Size() > 0){
            insert lstattch;
            system.debug('====>>'+lstattch);
            
        }*/
        
        }
        
        /*PageReference pr;
blob pdf;

for(Pay_In_Slip__c objPis : mapofPISTOInsert.values())
{    
pr = New PageReference('/apex/PIS_GenerationVFPage?id=' + objPis.id );                
pdf = pr.getContentAsPDF();                
Attachment a = New Attachment();
a.body = pdf;
a.parentID = objPis.id;
a.Name = 'FSA.pdf';
insert a;

}*/
    }
    global void finish(Database.BatchableContext BC)
    { 
        App_Configuration__c appObj =[Select ServiceAuditNumber__c from App_Configuration__c Limit 1 ];
        
        System.debug('ServiceAuditNumber__c ==> ' + appObj.ServiceAuditNumber__c);
        
        List<Messaging.SingleEmailMessage> mails =   new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail =  new Messaging.SingleEmailMessage();
        List<String> sendTo = new List<String>();
        sendTo.add('satish.tale@skinternational.com');
        mail.setToAddresses(sendTo);
        
        List<String> ccTo = new List<String>();
        ccTo.add('madhuri.tank@skinternational.com');
        
        mail.setCcAddresses(ccTo);
        
        mail.setSenderDisplayName('Hicare Services Pvt. Ltd');
        mail.setSubject('Auto Pay In Slip Batch process');
        Datetime myDT = System.now();
        String myDate = myDT.format();
        
        String body = 'Hello Team' + ' , ';
        body+= ' Auto Pay In Slip Batch successfully processed at Date/Time ' + myDate + '.';
        body+= ' Total ' + appObj.ServiceAuditNumber__c + ' Auto Pay In Slip has updated with the Attachment.';
        
        mail.setHtmlBody(body); 
        mails.add(mail);
        //Messaging.sendEmail(mails);
    }    
}