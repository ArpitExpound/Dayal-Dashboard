@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Root View for Looker'
@Metadata.allowExtensions: true
@ObjectModel.usageType: {
    serviceQuality: #X,
    sizeCategory: #S,
    dataClass: #MIXED
}
define root view entity ZI_DASH
  as select from    I_BillingDocument         as Billing
    inner join      I_Customer                as C    on Billing.SoldToParty = C.Customer
    inner join      I_DistributionChannel     as DC   on Billing.DistributionChannel = DC.DistributionChannel
    left outer join I_DistributionChannelText as DCT  on  DC.DistributionChannel = DCT.DistributionChannel
                                                      and DCT.Language           = $session.system_language
    inner join      I_Division                as Div  on Billing.Division = Div.Division
    left outer join I_DivisionText            as DivT on  Div.Division  = DivT.Division
                                                      and DivT.Language = $session.system_language
    inner join      I_CompanyCode             as Comp on Billing.CompanyCode = Comp.CompanyCode
{
      /*** Key & Basic Billing Info ***/
  key Billing.BillingDocument                          as BillingDocNo,
      Billing.CompanyCode                              as Company,
      Comp.CompanyCodeName                             as CompanyName,

      concat(
      concat(
      substring(Billing.BillingDocumentDate, 1, 4),
      concat('-', substring(Billing.BillingDocumentDate, 5, 2))
      ),
      concat('-', substring(Billing.BillingDocumentDate, 7, 2))
      )                                                as BillingDate,



      /*** Org & Master Data Fields ***/
      Billing.Division,
      DivT.DivisionName                                as DivisionName,
      Billing.DistributionChannel                      as Channel,
      DCT.DistributionChannelName                      as ChannelName,
      Billing.SoldToParty                              as CustomerCode,
      C.CustomerName                                   as CustomerName,

      /*** Currency & Amount Fields ***/
      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast( Billing.TotalNetAmount as abap.dec(16,2) ) as NetAmounts,

      @Semantics.amount.currencyCode: 'TransactionCurrency'
      cast( Billing.TotalTaxAmount as abap.dec(16,2) ) as TaxAmounts,

      Billing.TransactionCurrency,
      Billing.SDDocumentCategory,
      Billing.BillingDocumentIsCancelled,
      Billing.CancelledBillingDocument,

      /*** Derived Revenue and GST Fields ***/
      case
          when ( Billing.SDDocumentCategory = 'M' or Billing.SDDocumentCategory = 'P' )
              then cast( Billing.TotalNetAmount as abap.dec(16,2) )
          else cast( 0 as abap.dec(16,2) )
      end                                              as InvoiceDebit_Rev,

      case
          when ( Billing.SDDocumentCategory = 'M' or Billing.SDDocumentCategory = 'P' )
              then cast( Billing.TotalTaxAmount as abap.dec(16,2) )
          else cast( 0 as abap.dec(16,2) )
      end                                              as InvoiceDebit_GST,

      case
          when Billing.SDDocumentCategory = 'O'
              then cast( Billing.TotalNetAmount as abap.dec(16,2) )
          else cast( 0 as abap.dec(16,2) )
      end                                              as CreditNoteValue,

      case
          when Billing.SDDocumentCategory = 'O'
              then cast( Billing.TotalTaxAmount as abap.dec(16,2) )
          else cast( 0 as abap.dec(16,2) )
      end                                              as CreditNoteGST
}
where
  (
       Billing.SDDocumentCategory         = 'M'
    or Billing.SDDocumentCategory         = 'O'
    or Billing.SDDocumentCategory         = 'P'
  )
  and  Billing.BillingDocumentIsCancelled = ''
  and  Billing.CancelledBillingDocument   = '';
