@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'ZC_DASH'
@Metadata.allowExtensions: true
@ObjectModel.usageType:{
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZC_DASH
  as projection on ZI_DASH
{
  key BillingDocNo,
      Company,
      CompanyName,
      BillingDate,
      Division,
      DivisionName,
      Channel,
      ChannelName,
      CustomerCode,
      CustomerName,
      SalesDistrict,
      SalesDistrictName,
      Segment,
      SegmentName,
      NetAmounts,
      TaxAmounts,
      TransactionCurrency,
      SDDocumentCategory,
      BillingDocumentIsCancelled,
      CancelledBillingDocument,
      InvoiceDebit_Rev,
      InvoiceDebit_GST,
      CreditNoteValue,
      CreditNoteGST
}
