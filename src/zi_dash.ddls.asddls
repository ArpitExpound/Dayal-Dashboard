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
  as select from    I_BillingDocument              as Billing
    inner join      I_Customer                     as C        on Billing.SoldToParty = C.Customer
    inner join      I_DistributionChannel          as DC       on Billing.DistributionChannel = DC.DistributionChannel
    left outer join I_DistributionChannelText      as DCT      on  DC.DistributionChannel = DCT.DistributionChannel
                                                               and DCT.Language           = $session.system_language
    inner join      I_Division                     as Div      on Billing.Division = Div.Division
    left outer join I_DivisionText                 as DivT     on  Div.Division  = DivT.Division
                                                               and DivT.Language = $session.system_language
    inner join      I_CompanyCode                  as Comp     on Billing.CompanyCode = Comp.CompanyCode
    left outer join I_CustomerSalesArea            as CSA      on  CSA.Customer            = Billing.SoldToParty
                                                               and CSA.SalesOrganization   = Billing.SalesOrganization
                                                               and CSA.DistributionChannel = Billing.DistributionChannel
                                                               and CSA.Division            = Billing.Division
    left outer join I_SalesDistrict                as SD       on CSA.SalesDistrict = SD.SalesDistrict
    left outer join I_SalesDistrictText            as SDT      on  SD.SalesDistrict = SDT.SalesDistrict
                                                               and SDT.Language     = $session.system_language
    left outer join I_PrftCtrCompanyCodeAssignment as PCAssign on PCAssign.CompanyCode = Billing.CompanyCode

  // Step 2: Join ProfitCenter master
    left outer join I_ProfitCenter                 as ProfCtr  on  ProfCtr.ProfitCenter    = PCAssign.ProfitCenter
                                                               and ProfCtr.ControllingArea = PCAssign.ControllingArea

  // Step 3: Join Segment and its text
    left outer join I_Segment                      as Seg      on Seg.Segment = ProfCtr.Segment
    left outer join I_SegmentText                  as SegTxt   on  SegTxt.Segment  = Seg.Segment
                                                               and SegTxt.Language = $session.system_language
{
      /*** Key & Basic Billing Info ***/
  key Billing.BillingDocument                          as BillingDocNo,
      Billing.CompanyCode                              as Company,
      Comp.CompanyCodeName                             as CompanyName,

      /*** Date formatted as YYYY-MM-DD ***/
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

      CSA.SalesDistrict                                as SalesDistrict,
      SDT.SalesDistrictName                            as SalesDistrictName,
      ProfCtr.Segment                                  as Segment,
      SegTxt.SegmentName                               as SegmentName,

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
