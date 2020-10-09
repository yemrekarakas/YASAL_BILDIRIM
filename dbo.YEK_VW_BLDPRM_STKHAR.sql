
CREATE VIEW dbo.YEK_VW_BLDPRM_STKHAR
AS
    SELECT
        STKHAR.*
       ,ISNULL( STHVRG.SABITVERGI1, 0 ) AS SABITVERGI1
       ,ISNULL( STHVRG.SABITVERGI2, 0 ) AS SABITVERGI2
       ,ISNULL( STHVRG.SABITVERGI3, 0 ) AS SABITVERGI3
       ,STHVRG.MHSBELGENO AS MHSBELGENO
       ,STHVRG.MHSBELGETARIH AS MHSBELGETARIH
       ,BILDIRIMHESAPKOD = ( CASE
                                 WHEN STKHAR.EVRAKTIP = 689 THEN ( CASE ISNULL( STHVRG.VERGIHESAPNO, '' )
                                                                       WHEN '' THEN ( CASE STKHAR.KARSIHESAPKOD
                                                                                          WHEN '' THEN STKHAR.HESAPKOD
                                                                                          ELSE STKHAR.KARSIHESAPKOD
                                                                                      END
                                                                                    )
                                                                       ELSE ISNULL( STHVRG.VERGIHESAPNO, '' )
                                                                   END
                                                                 )
                                 ELSE STKHAR.HESAPKOD
                             END
                           )
       ,BILDIRIMMATRAH = ( STKHAR.TUTAR - STKHAR.ISKONTO + STKHAR.OTV ) + ISNULL( STHVRG.SABITVERGI1, 0 ) + ISNULL( STHVRG.SABITVERGI2, 0 ) + ISNULL( STHVRG.SABITVERGI3, 0 ) + ( CASE STKHAR.SKOD5
                                                                                                                                                                                      WHEN 'OIV99' THEN STKHAR.KDV
                                                                                                                                                                                      ELSE 0
                                                                                                                                                                                  END
                                                                                                                                                                                )
       ,ISNULL( CARKRT.MKOD1, '' ) CARKRT_MKOD1
    FROM dbo.STKHAR WITH ( NOLOCK )
         LEFT OUTER JOIN dbo.CARKRT CARKRT WITH ( NOLOCK ) ON STKHAR.HESAPKOD = CARKRT.HESAPKOD
         LEFT OUTER JOIN dbo.STHVRG STHVRG WITH ( NOLOCK ) ON (
                                                                  STHVRG.SIRKETNO = STKHAR.SIRKETNO
                                                                  AND STHVRG.EVRAKTIP = STKHAR.EVRAKTIP
                                                                  AND STHVRG.HESAPKOD = STKHAR.HESAPKOD
                                                                  AND STHVRG.EVRAKNO = STKHAR.EVRAKNO
                                                                  AND STHVRG.KONSOLIDESIRKETNO = STKHAR.KONSOLIDESIRKETNO
                                                                  AND STHVRG.SIRANO = STKHAR.SIRANO
                                                              )
GO