# YASAL_BILDIRIM

Cpm Master ERP programında mevcut teblig bildirim prosedurune CARKRT_MKOD1 parametresi eklenmiştir.

```SQL
EXEC dbo.YEK_TEBLIG_BILDIRIM_FORM
    @SIRKETNO = '001'          -- varchar(3)
   ,@BASTARIH = '2020-09-01'   -- smalldatetime
   ,@BITISTARIH = '2020-09-30' -- smalldatetime
   ,@TEBLIGTUTAR = 5000        -- numeric(25, 6)
   ,@KDVAYRIM = 0              -- smallint
   ,@VERGIAYRIM = 0            -- smallint
   ,@YUVARLA = 0               -- smallint
   ,@BILDIRIMKOD = 'BS'        -- varchar(4)
   ,@KONSOLIDESIRKETNO = ''    -- varchar(3)
   ,@RSKPRM_ID = 0             -- int
   ,@BILDIRIM_MHSFIS = 0       -- smallint
   ,@CARKRT_MKOD1 = '0'        -- varchar(12)
```