CREATE VIEW dbo.YEK_VW_BLDPRM_CARKRT
AS
    SELECT
        HESAPKOD
       ,UNVAN
       ,UNVAN2
       ,VERGIDAIRE
       ,VERGIHESAPNO
       ,ULKEKOD = ( CASE ULKEKOD
                        WHEN '' THEN '052'
                        ELSE ULKEKOD
                    END
                  )
       ,FATURAADRES1
       ,FATURAADRES2
       ,FATURAADRES3
       ,FATURAADRES4
       ,FATURAADRES5
       ,TELEFON1
       ,TELEFON2
       ,TELEFON3
       ,TELEFON4
       ,TELEFON5
       ,FAX1
       ,FAX2
       ,FAX3
       ,FAX4
       ,FAX5
       ,EMAIL1
       ,EMAIL2
       ,EMAIL3
       ,EMAIL4
       ,EMAIL5
       ,BABSTIP
       ,MKOD1
    FROM dbo.CARKRT WITH ( NOLOCK )
    UNION ALL
    SELECT
        VERGIHESAPNO
       ,UNVAN
       ,UNVAN2
       ,VERGIDAIRE
       ,VERGIHESAPNO
       ,ULKEKOD = ( CASE ULKEKOD
                        WHEN '' THEN '052'
                        ELSE ULKEKOD
                    END
                  )
       ,FATURAADRES1
       ,FATURAADRES2
       ,FATURAADRES3
       ,FATURAADRES4
       ,FATURAADRES5
       ,TELEFON1
       ,TELEFON2
       ,TELEFON3
       ,TELEFON4
       ,TELEFON5
       ,FAX1
       ,FAX2
       ,FAX3
       ,FAX4
       ,FAX5
       ,EMAIL1
       ,EMAIL2
       ,EMAIL3
       ,EMAIL4
       ,EMAIL5
       ,1 AS BABSTIP
       ,''
    FROM dbo.MHSVHK WITH ( NOLOCK )
GO