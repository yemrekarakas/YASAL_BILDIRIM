CREATE PROCEDURE dbo.YEK_TEBLIG_BILDIRIM_FORM
    @SIRKETNO          VARCHAR(3)     = ''
   ,@BASTARIH          SMALLDATETIME  = 0
   ,@BITISTARIH        SMALLDATETIME  = 0
   ,@TEBLIGTUTAR       NUMERIC(25, 6) = 0
   ,@KDVAYRIM          SMALLINT       = 0
   ,@VERGIAYRIM        SMALLINT       = 0
   ,@YUVARLA           SMALLINT       = 0
   ,@BILDIRIMKOD       VARCHAR(4)     = ''
   ,@KONSOLIDESIRKETNO VARCHAR(3)     = ''
   ,@RSKPRM_ID         INT            = 0
   ,@BILDIRIM_MHSFIS   SMALLINT       = 0
   ,@CARKRT_MKOD1      VARCHAR(12)    = ''
WITH EXECUTE AS CALLER
AS
    DECLARE
        @HESAPKOD VARCHAR(30)
       ,@KDVORAN  REAL
       ,@MATRAH   NUMERIC(25, 6)
       ,@KDVTUTAR NUMERIC(25, 6)
    DECLARE
        @KDVKESINTIORAN REAL
       ,@KDVKESINTI     NUMERIC(25, 6)
       ,@CARIBAKIYE     NUMERIC(25, 6)
    DECLARE
        @FATURAADET   INT
       ,@VERGIHESAPNO VARCHAR(30)
    DECLARE
        @WHERECLAUSE_STKHAR VARCHAR(1000)
       ,@WHERECLAUSE_TCKMSR VARCHAR(1000)
       ,@WHERECLAUSE_MHSFIS VARCHAR(1000)
    DECLARE
        @SQLSTRING   NVARCHAR(4000)
       ,@STOK_CURSOR CURSOR
       ,@MHS_CURSOR  CURSOR
    DECLARE @WHERESTR_CARIBAKIYE VARCHAR(100)
    DECLARE
        @DONEMYIL   INT
       ,@DONEMBASAY SMALLINT
       ,@DONEMBITAY SMALLINT
       ,@SATIRTIP   SMALLINT
    DECLARE
        @BASBILDIRIMKOD   VARCHAR(4)
       ,@BITISBILDIRIMKOD VARCHAR(4)
       ,@STRKDVKESINTI    VARCHAR(100)
    DECLARE
        @RSKPRM_KULLANICIAD   VARCHAR(30)
       ,@RSKPRM_PARAMETREAD   VARCHAR(100)
       ,@RSKPRM_CARHARTABLOAD VARCHAR(30)
    DECLARE @WHERECLAUSE_CARKRT VARCHAR(50)

    BEGIN
        SET NOCOUNT ON

        IF @BILDIRIMKOD = '' --Mutabakat  raporu i�in
        BEGIN
            SET @BASBILDIRIMKOD = 'BA'
            SET @BITISBILDIRIMKOD = 'BS'
        END
        ELSE
        BEGIN
            SET @BASBILDIRIMKOD = @BILDIRIMKOD
            SET @BITISBILDIRIMKOD = @BILDIRIMKOD
        END

        SET @DONEMBASAY = MONTH( @BASTARIH )
        SET @DONEMBITAY = MONTH( @BITISTARIH )
        SET @DONEMYIL = YEAR( @BITISTARIH )

        IF @CARKRT_MKOD1 <> ''
        BEGIN
            SET @WHERECLAUSE_CARKRT = ' AND CARKRT_MKOD1  = ''' + @CARKRT_MKOD1 + ''''
        END
        ELSE
        BEGIN
            SET @WHERECLAUSE_CARKRT = ''
        END

        CREATE TABLE #BILDIRIMFORM
        (
            ID             INTEGER NOT NULL IDENTITY(1, 1)
           ,BILDIRIMKOD    VARCHAR(4)
           ,HESAPKOD       VARCHAR(30)
           ,VERGIHESAPNO   VARCHAR(30)
           ,MATRAH         NUMERIC(25, 6)
           ,KDVORAN        REAL
           ,KDVTUTAR       NUMERIC(25, 6)
           ,KDVKESINTIORAN REAL
           ,KDVKESINTI     NUMERIC(25, 6)
           ,SATIRTIP       SMALLINT
        )

        CREATE TABLE #EVRAKADET
        (
            ID           INTEGER NOT NULL IDENTITY(1, 1)
           ,BILDIRIMKOD  VARCHAR(4)
           ,HESAPKOD     VARCHAR(30)
           ,VERGIHESAPNO VARCHAR(30)
           ,FATURAADET   INT
           ,CARIBAKIYE   NUMERIC(25, 6)
           ,SATIRTIP     SMALLINT
        )

        IF @RSKPRM_ID > 0
        BEGIN
            SELECT @RSKPRM_KULLANICIAD = KULLANICIAD, @RSKPRM_PARAMETREAD = PARAMETREAD, @RSKPRM_CARHARTABLOAD = CARHARTABLOAD FROM RSKPRM WHERE ID = @RSKPRM_ID

            CREATE TABLE #CARIBAKIYE
            (
                -- Keys
                ID                         INT NOT NULL
               ,ANAHTARKOD                 VARCHAR(150)
               ,KARTKOD                    VARCHAR(30)
               ,HAREKETKOD                 VARCHAR(30)
               ,HAREKETKOD2                VARCHAR(30)
               ,HAREKETKOD3                VARCHAR(30)
               ,DOVIZCINS                  VARCHAR(3)
               -- Tutar Top
               ,BORC                       NUMERIC(25, 6)
               ,ALACAK                     NUMERIC(25, 6)
               ,BAKIYE                     NUMERIC(25, 6)
               ,BORCBAKIYE                 NUMERIC(25, 6)
               ,ALACAKBAKIYE               NUMERIC(25, 6)
               ,KAPAMABAKIYE               NUMERIC(25, 6)
               ,GECIKENBAKIYE              NUMERIC(25, 6)
               ,VADEGELENBAKIYE            NUMERIC(25, 6)
               ,CEKSENETTOPLAM             NUMERIC(25, 6)
               ,RISKLIBAKIYE               NUMERIC(25, 6)
               ,KARSILIKSIZBAKIYE          NUMERIC(25, 6)
               -- D�viz Top
               ,DOVIZBORC                  NUMERIC(25, 6)
               ,DOVIZALACAK                NUMERIC(25, 6)
               ,DOVIZBAKIYE                NUMERIC(25, 6)
               ,DOVIZKAPAMABAKIYE          NUMERIC(25, 6)
               ,DOVIZGECIKENBAKIYE         NUMERIC(25, 6)
               ,DOVIZVADEGELENBAKIYE       NUMERIC(25, 6)
               ,DOVIZCEKSENETTOPLAM        NUMERIC(25, 6)
               ,DOVIZRISKLIBAKIYE          NUMERIC(25, 6)
               ,DOVIZKARSILIKSIZBAKIYE     NUMERIC(25, 6)
               -- Ekstre
               ,EKSTREBORC                 NUMERIC(25, 6)
               ,EKSTREALACAK               NUMERIC(25, 6)
               ,EKSTREBAKIYE               NUMERIC(25, 6)
               -- Ort. Vade
               ,BORCORTVADE                DATETIME
               ,ALACAKORTVADE              DATETIME
               ,BAKIYEORTVADE              DATETIME
               ,GECIKENBAKIYEORTVADE       DATETIME
               ,KAPATANVADE                DATETIME
               -- Ort. ��lem Tarih
               ,BORCORTISLEMTARIH          DATETIME
               ,ALACAKORTISLEMTARIH        DATETIME
               ,BAKIYEORTISLEMTARIH        DATETIME
               ,GECIKENBAKIYEORTISLEMTARIH DATETIME
               -- Onaylanmam�� E�leme Vade/Kur Fark�
               ,KAPANANTUTAR               NUMERIC(25, 6)
               ,KAPANANBORCORTVADE         DATETIME
               ,KAPANANALACAKORTVADE       DATETIME
               ,KAPANANBORCORTISLEMTARIH   DATETIME
               ,KAPANANALACAKORTISLEMTARIH DATETIME
               ,KAPANANBEKLEMESURE         INT
               ,KAPANANVADEFARKGUN         INT
               ,KAPANANOPSIYON             INT
               ,KAPANANVADEFARK            NUMERIC(25, 6)
               ,KESILENVADEFARK            NUMERIC(25, 6)
               ,KALANVADEFARK              NUMERIC(25, 6)
               ,KAPANANKURFARK             NUMERIC(25, 6)
               -- Onaylanm�� E�leme Vade/Kur Fark�
               ,ONAYLITUTAR                NUMERIC(25, 6)
               ,ONAYLIBORCORTVADE          DATETIME
               ,ONAYLIALACAKORTVADE        DATETIME
               ,ONAYLIVADEFARKGUN          INT
               ,ONAYLIVADEFARK             NUMERIC(25, 6)
               ,ONAYLIKESILENVADEFARK      NUMERIC(25, 6)
               ,ONAYLIKALANVADEFARK        NUMERIC(25, 6)
               ,ONAYLIKURFARK              NUMERIC(25, 6)
               -- Bakiye Vade Fark
               ,BAKIYEBEKLEMESURE          INT
               ,BAKIYEVADEFARKGUN          INT
               ,BAKIYEOPSIYON              INT
               -- Geciken Bakiye Vade Fark
               ,GECIKENBAKIYEBEKLEMESURE   INT
               ,GECIKENBAKIYEVADEFARKGUN   INT
               ,GECIKENBAKIYEOPSIYON       INT
               ,GECIKENBAKIYEVADEFARK      NUMERIC(25, 6)
               -- �lk/Son Evrak Bilgileri
               ,BAKIYEILKEVRAKTARIH        DATETIME
               ,BAKIYEILKEVRAKNO           VARCHAR(30)
               ,GECIKENBAKIYEILKEVRAKTARIH DATETIME
               ,GECIKENBAKIYEILKEVRAKNO    VARCHAR(30)
               ,BORCSONEVRAKTARIH          DATETIME
               ,BORCSONEVRAKNO             VARCHAR(30)
               ,ALACAKSONEVRAKTARIH        DATETIME
               ,ALACAKSONEVRAKNO           VARCHAR(30)
               -- G�ncel Bakiye
               ,GUNCELBAKIYE               NUMERIC(25, 6)
               ,BAKIYEKURFARK              NUMERIC(25, 6)
               ,DEGERLEMETOPLAM            NUMERIC(25, 6)
               -- Hesaplanan Alanlar
               ,HTUTAR1                    NUMERIC(25, 6)
               ,HTUTAR2                    NUMERIC(25, 6)
               ,HTUTAR3                    NUMERIC(25, 6)
               ,HTUTAR4                    NUMERIC(25, 6)
               ,HTUTAR5                    NUMERIC(25, 6)
               ,HTARIH1                    DATETIME
               ,HTARIH2                    DATETIME
               ,HACIKLAMA                  VARCHAR(50)
            )
        END

        DECLARE BILDIRIM_CURSOR CURSOR LOCAL FAST_FORWARD FOR(
            SELECT
                BILDIRIMKOD
               ,STRSTKHAR
               ,STRTCKMSR
               ,STRMHSFIS
            FROM dbo.BLDPRM
            WHERE SIRKETNO = @SIRKETNO
                AND ( BILDIRIMKOD BETWEEN @BASBILDIRIMKOD AND @BITISBILDIRIMKOD )
                AND KONSOLIDESIRKETNO = @KONSOLIDESIRKETNO)

        OPEN BILDIRIM_CURSOR

        FETCH NEXT FROM BILDIRIM_CURSOR
        INTO
            @BILDIRIMKOD
           ,@WHERECLAUSE_STKHAR
           ,@WHERECLAUSE_TCKMSR
           ,@WHERECLAUSE_MHSFIS

        WHILE ( @@FETCH_STATUS = 0 )
        BEGIN
            IF @BILDIRIMKOD = 'BA'
                OR @BILDIRIMKOD = 'BS'
            BEGIN
                SET @WHERECLAUSE_STKHAR = ( CASE ISNULL( @WHERECLAUSE_STKHAR, '' )
                                                WHEN '' THEN ' AND (STKHAR.ID = -1)'
                                                ELSE ( ' AND (' + @WHERECLAUSE_STKHAR ) + ')'
                                            END
                                          )
                SET @WHERECLAUSE_TCKMSR = ( CASE ISNULL( @WHERECLAUSE_TCKMSR, '' )
                                                WHEN '' THEN ' AND (TCKMSR.ID = -1)'
                                                ELSE ( ' AND (' + @WHERECLAUSE_TCKMSR ) + ')'
                                            END
                                          )
                SET @WHERECLAUSE_MHSFIS = ( CASE ISNULL( @WHERECLAUSE_MHSFIS, '' )
                                                WHEN '' THEN ' AND (MHSFIS.ID = -1)'
                                                ELSE ( ' AND (' + @WHERECLAUSE_MHSFIS ) + ')'
                                            END
                                          )
                SET @SQLSTRING = N'SET @CURSOR = CURSOR LOCAL FAST_FORWARD FOR (
					SELECT 
						TMP.HESAPKOD, TMP.KDVORAN, TMP.KDVKESINTIORAN, SUM(TMP.MATRAH) AS MATRAH, SUM(TMP.KDVTUTAR) AS KDVTUTAR, SUM(TMP.KDVKESINTI) AS KDVKESINTI
					FROM 
					(
						SELECT 
							BILDIRIMHESAPKOD AS HESAPKOD,
							(CASE @KDVAYRIM WHEN 1 THEN STKHAR.KDVORAN ELSE CAST(0 AS REAL) END) AS KDVORAN,
							(CASE @KDVAYRIM WHEN 1 THEN STKHAR.KDVKESINTIORAN ELSE CAST(0 AS REAL) END) AS KDVKESINTIORAN,
							BILDIRIMMATRAH AS MATRAH, STKHAR.KDV AS KDVTUTAR, STKHAR.KDVKESINTI AS KDVKESINTI
						FROM YEK_VW_BLDPRM_STKHAR AS STKHAR
						WHERE STKHAR.SIRKETNO=@SIRKETNO AND (MHSBELGETARIH BETWEEN @BASTARIH AND @BITISTARIH) ' + @WHERECLAUSE_STKHAR + N' ' + @WHERECLAUSE_CARKRT + N'
						UNION ALL 
						SELECT 
							BILDIRIMHESAPKOD AS HESAPKOD,
							(CASE @KDVAYRIM WHEN 1 THEN TCKMSR.EVRAKKDVORAN ELSE CAST(0 AS REAL) END) AS KDVORAN,
							CAST(0 AS REAL) AS KDVKESINTIORAN,
							TCKMSR.TUTAR AS MATRAH, TCKMSR.KDV AS KDVTUTAR, CAST(0 AS NUMERIC(25,6)) AS KDVKESINTI 
						FROM VW_BLDPRM_TCKMSR AS TCKMSR
						WHERE SIRKETNO=@SIRKETNO AND MHSBELGETARIH BETWEEN @BASTARIH AND @BITISTARIH ' + @WHERECLAUSE_TCKMSR + N'
					) AS TMP, (SELECT HESAPKOD, BABSTIP FROM YEK_VW_BLDPRM_CARKRT) AS CARKRT 
					WHERE TMP.HESAPKOD = CARKRT.HESAPKOD AND CARKRT.BABSTIP = 1  
					GROUP BY TMP.HESAPKOD,TMP.KDVORAN, TMP.KDVKESINTIORAN
				) OPEN @CURSOR'

                EXEC SP_EXECUTESQL
                    @SQLSTRING
                   ,N'@SIRKETNO VARCHAR(3), @KDVAYRIM SMALLINT, @BASTARIH SMALLDATETIME, @BITISTARIH SMALLDATETIME, @B VARCHAR(1), @CURSOR CURSOR OUTPUT'
                   ,@SIRKETNO
                   ,@KDVAYRIM
                   ,@BASTARIH
                   ,@BITISTARIH
                   ,''
                   ,@STOK_CURSOR OUTPUT

                FETCH NEXT FROM @STOK_CURSOR
                INTO
                    @HESAPKOD
                   ,@KDVORAN
                   ,@KDVKESINTIORAN
                   ,@MATRAH
                   ,@KDVTUTAR
                   ,@KDVKESINTI

                WHILE ( @@FETCH_STATUS = 0 )
                BEGIN
                    IF @MATRAH > 0
                    BEGIN
                        IF @VERGIAYRIM = 0 -- Birle�tir
                            SET @VERGIHESAPNO = ISNULL((
                                                           SELECT TOP 1 VERGIHESAPNO FROM YEK_VW_BLDPRM_CARKRT WHERE HESAPKOD = @HESAPKOD AND BABSTIP = 1
                                                       )
                                                      ,''
                                                      )
                        ELSE
                            SET @VERGIHESAPNO = ''

                        IF NOT EXISTS ( SELECT * FROM #EVRAKADET WHERE BILDIRIMKOD = @BILDIRIMKOD AND HESAPKOD = @HESAPKOD )
                        BEGIN
                            INSERT INTO #EVRAKADET ( BILDIRIMKOD, HESAPKOD, VERGIHESAPNO, SATIRTIP ) VALUES ( @BILDIRIMKOD, @HESAPKOD, @VERGIHESAPNO, 0 )
                        END

                        IF ( @VERGIHESAPNO <> '1111111111' )
                            AND ( @VERGIHESAPNO <> '2222222222' )
                            AND ( @VERGIHESAPNO <> '' )
                        BEGIN
                            IF ( @VERGIAYRIM = 0 ) -- Birle�tir 
                                SET @HESAPKOD = ISNULL((
                                                           SELECT TOP 1 HESAPKOD FROM #BILDIRIMFORM WHERE BILDIRIMKOD = @BILDIRIMKOD AND VERGIHESAPNO = @VERGIHESAPNO
                                                       )
                                                      ,@HESAPKOD
                                                      )

                            IF NOT EXISTS
                            (
                                SELECT * FROM #BILDIRIMFORM WHERE BILDIRIMKOD = @BILDIRIMKOD AND HESAPKOD = @HESAPKOD AND KDVORAN = @KDVORAN AND KDVKESINTIORAN = @KDVKESINTIORAN
                            )
                            BEGIN
                                INSERT INTO #BILDIRIMFORM
                                (
                                    BILDIRIMKOD
                                   ,HESAPKOD
                                   ,VERGIHESAPNO
                                   ,MATRAH
                                   ,KDVORAN
                                   ,KDVTUTAR
                                   ,KDVKESINTIORAN
                                   ,KDVKESINTI
                                   ,SATIRTIP
                                )
                                VALUES
                                    ( @BILDIRIMKOD, @HESAPKOD, @VERGIHESAPNO, @MATRAH, @KDVORAN, @KDVTUTAR, @KDVKESINTIORAN, @KDVKESINTI, 0 )
                            END
                            ELSE
                            BEGIN
                                UPDATE #BILDIRIMFORM
                                SET
                                    MATRAH = MATRAH + @MATRAH
                                   ,KDVTUTAR = KDVTUTAR + @KDVTUTAR
                                   ,KDVKESINTI = KDVKESINTI + @KDVKESINTI
                                WHERE BILDIRIMKOD = @BILDIRIMKOD
                                    AND HESAPKOD = @HESAPKOD
                                    AND KDVORAN = @KDVORAN
                                    AND KDVKESINTIORAN = @KDVKESINTIORAN
                            END
                        END
                        ELSE
                        BEGIN
                            INSERT INTO #BILDIRIMFORM
                            (
                                BILDIRIMKOD
                               ,HESAPKOD
                               ,VERGIHESAPNO
                               ,MATRAH
                               ,KDVORAN
                               ,KDVTUTAR
                               ,KDVKESINTIORAN
                               ,KDVKESINTI
                               ,SATIRTIP
                            )
                            VALUES
                                ( @BILDIRIMKOD, @HESAPKOD, @VERGIHESAPNO, @MATRAH, @KDVORAN, @KDVTUTAR, @KDVKESINTIORAN, @KDVKESINTI, 0 )
                        END
                    END

                    FETCH NEXT FROM @STOK_CURSOR
                    INTO
                        @HESAPKOD
                       ,@KDVORAN
                       ,@KDVKESINTIORAN
                       ,@MATRAH
                       ,@KDVTUTAR
                       ,@KDVKESINTI
                END

                CLOSE @STOK_CURSOR
                DEALLOCATE @STOK_CURSOR

                IF @BILDIRIM_MHSFIS = 1
                BEGIN
                    SET @SQLSTRING = N'SET @CURSOR = CURSOR LOCAL FAST_FORWARD FOR (
							SELECT 
								BILDIRIMHESAPKOD AS VERGIHESAPNO, SUM(TUTAR)
							FROM VW_BLDPRM_MHSFIS AS MHSFIS
							WHERE SIRKETNO=@SIRKETNO AND DEFTERTIP = 0  AND VERGIHESAPNO <> '''' AND BELGETARIH BETWEEN @BASTARIH AND @BITISTARIH ' + @WHERECLAUSE_MHSFIS + N'
							GROUP BY BILDIRIMHESAPKOD
					) OPEN @CURSOR'

                    EXEC SP_EXECUTESQL
                        @SQLSTRING
                       ,N'@SIRKETNO VARCHAR(3), @BASTARIH SMALLDATETIME, @BITISTARIH SMALLDATETIME, @CURSOR CURSOR OUTPUT'
                       ,@SIRKETNO
                       ,@BASTARIH
                       ,@BITISTARIH
                       ,@MHS_CURSOR OUTPUT

                    FETCH NEXT FROM @MHS_CURSOR
                    INTO
                        @VERGIHESAPNO
                       ,@MATRAH

                    WHILE ( @@FETCH_STATUS = 0 )
                    BEGIN
                        SET @HESAPKOD = @VERGIHESAPNO

                        IF NOT EXISTS ( SELECT * FROM #EVRAKADET WHERE BILDIRIMKOD = @BILDIRIMKOD AND HESAPKOD = @HESAPKOD )
                        BEGIN
                            INSERT INTO #EVRAKADET ( BILDIRIMKOD, HESAPKOD, VERGIHESAPNO, SATIRTIP ) VALUES ( @BILDIRIMKOD, @HESAPKOD, @VERGIHESAPNO, 1 )
                        END

                        SET @KDVORAN = 0
                        SET @KDVTUTAR = 0

                        IF NOT EXISTS ( SELECT * FROM #BILDIRIMFORM WHERE BILDIRIMKOD = @BILDIRIMKOD AND HESAPKOD = @HESAPKOD AND KDVORAN = @KDVORAN )
                        BEGIN
                            INSERT INTO #BILDIRIMFORM
                            (
                                BILDIRIMKOD
                               ,HESAPKOD
                               ,VERGIHESAPNO
                               ,MATRAH
                               ,KDVORAN
                               ,KDVTUTAR
                               ,KDVKESINTIORAN
                               ,KDVKESINTI
                               ,SATIRTIP
                            )
                            VALUES
                                ( @BILDIRIMKOD, @HESAPKOD, @VERGIHESAPNO, @MATRAH, @KDVORAN, 0, 0, 0, 1 )
                        END
                        ELSE
                        BEGIN
                            UPDATE #BILDIRIMFORM SET MATRAH = MATRAH + @MATRAH, KDVTUTAR = KDVTUTAR + @KDVTUTAR WHERE BILDIRIMKOD = @BILDIRIMKOD AND HESAPKOD = @HESAPKOD AND KDVORAN = @KDVORAN
                        END

                        FETCH NEXT FROM @MHS_CURSOR
                        INTO
                            @VERGIHESAPNO
                           ,@MATRAH
                    END

                    CLOSE @MHS_CURSOR
                    DEALLOCATE @MHS_CURSOR
                END

                IF @TEBLIGTUTAR > 0
                BEGIN
                    DECLARE X_CURSOR CURSOR LOCAL FAST_FORWARD FOR(
                        SELECT HESAPKOD, SUM( MATRAH )FROM #BILDIRIMFORM WHERE BILDIRIMKOD = @BILDIRIMKOD GROUP BY HESAPKOD)

                    OPEN X_CURSOR

                    FETCH NEXT FROM X_CURSOR
                    INTO
                        @HESAPKOD
                       ,@MATRAH

                    WHILE ( @@FETCH_STATUS = 0 )
                    BEGIN
                        IF @MATRAH < @TEBLIGTUTAR
                        BEGIN
                            DELETE #BILDIRIMFORM WHERE BILDIRIMKOD = @BILDIRIMKOD AND HESAPKOD = @HESAPKOD

                            DELETE #EVRAKADET WHERE BILDIRIMKOD = @BILDIRIMKOD AND HESAPKOD = @HESAPKOD
                        END

                        FETCH NEXT FROM X_CURSOR
                        INTO
                            @HESAPKOD
                           ,@MATRAH
                    END

                    CLOSE X_CURSOR
                    DEALLOCATE X_CURSOR
                END
            END

            DECLARE X_CURSOR CURSOR LOCAL FAST_FORWARD FOR(
                SELECT HESAPKOD, SATIRTIP FROM #EVRAKADET WHERE BILDIRIMKOD = @BILDIRIMKOD)

            OPEN X_CURSOR

            FETCH NEXT FROM X_CURSOR
            INTO
                @HESAPKOD
               ,@SATIRTIP

            WHILE ( @@FETCH_STATUS = 0 )
            BEGIN
                IF @SATIRTIP = 0
                BEGIN
                    IF @RSKPRM_ID > 0 -- Cari hesap bakiye 
                    BEGIN
                        IF NOT EXISTS ( SELECT * FROM #CARIBAKIYE WHERE ANAHTARKOD = @HESAPKOD )
                        BEGIN
                            SET @WHERESTR_CARIBAKIYE = ' CARKRT.HESAPKOD=''' + @HESAPKOD + ''''

                            INSERT INTO #CARIBAKIYE
                            EXECUTE dbo.SPAPPRY_KAPAMA_RUN
                                @SIRKETNO = @SIRKETNO
                               ,@KULLANICIAD = @RSKPRM_KULLANICIAD
                               ,@PARAMETREAD = @RSKPRM_PARAMETREAD
                               ,@RAPORTARIH = @BITISTARIH
                               ,@BUGUNTARIH = @BITISTARIH
                               ,@SECILIALANLAR = ''
                               ,@WHERESTR = @WHERESTR_CARIBAKIYE
                               ,@TABLENAME_CARHAR = @RSKPRM_CARHARTABLOAD
                               ,@TABLEREFNAME_CARHAR = ''
                               ,@TABLENAME_CARKRT = ''
                               ,@TABLEREFNAME_CARKRT = ''
                               ,@GOSTERIMTIP = 1
                        END

                        UPDATE #EVRAKADET SET CARIBAKIYE = @CARIBAKIYE WHERE BILDIRIMKOD = @BILDIRIMKOD AND HESAPKOD = @HESAPKOD
                    END

                    IF @KDVAYRIM = 0 -- KDV Oran Ayr�m� Yoksa 
                    BEGIN
                        SET @FATURAADET = 0
                        SET @SQLSTRING = N'SET @FATURAADET = ISNULL(
								(SELECT COUNT(*) FROM 
												(
												SELECT 
													DISTINCT MHSBELGENO
												FROM VW_BLDPRM_STKHAR AS STKHAR
												WHERE SIRKETNO=@SIRKETNO AND MHSBELGETARIH BETWEEN @BASTARIH AND @BITISTARIH AND BILDIRIMHESAPKOD=@HESAPKOD ' + @WHERECLAUSE_STKHAR + N'
												UNION ALL 
												SELECT 
													DISTINCT MHSBELGENO
												FROM VW_BLDPRM_TCKMSR AS TCKMSR
												WHERE SIRKETNO=@SIRKETNO AND MHSBELGETARIH BETWEEN @BASTARIH AND @BITISTARIH AND BILDIRIMHESAPKOD=@HESAPKOD ' + @WHERECLAUSE_TCKMSR + N'
												) AS CNT
								),0)'

                        EXEC SP_EXECUTESQL
                            @SQLSTRING
                           ,N'@SIRKETNO VARCHAR(3), @BASTARIH SMALLDATETIME, @BITISTARIH SMALLDATETIME, @HESAPKOD VARCHAR(30), @KDVORAN REAL, @FATURAADET INT OUTPUT'
                           ,@SIRKETNO
                           ,@BASTARIH
                           ,@BITISTARIH
                           ,@HESAPKOD
                           ,@KDVORAN
                           ,@FATURAADET OUTPUT

                        UPDATE #EVRAKADET SET FATURAADET = @FATURAADET WHERE BILDIRIMKOD = @BILDIRIMKOD AND HESAPKOD = @HESAPKOD
                    END --ALICI YADA SATICININ B�RDEN FAZLA CAR� KART VARSA VERG� HESAP NO BAZINDA B�RLE�T�R.			
                END
                ELSE -- Muhasebe
                BEGIN
                    SET @SQLSTRING = N'SET @FATURAADET = ISNULL((SELECT COUNT(*) FROM 
						(SELECT  DISTINCT BELGENO FROM VW_BLDPRM_MHSFIS  AS MHSFIS
						WHERE SIRKETNO=@SIRKETNO  AND DEFTERTIP=0 AND VERGIHESAPNO=@VERGIHESAPNO AND BELGETARIH BETWEEN @BASTARIH AND @BITISTARIH' + @WHERECLAUSE_MHSFIS + N'
						) AS CNT),0)'

                    EXEC SP_EXECUTESQL
                        @SQLSTRING
                       ,N'@SIRKETNO VARCHAR(3), @BASTARIH SMALLDATETIME, @BITISTARIH SMALLDATETIME, @VERGIHESAPNO VARCHAR(30),  @FATURAADET INT OUTPUT'
                       ,@SIRKETNO
                       ,@BASTARIH
                       ,@BITISTARIH
                       ,@HESAPKOD
                       ,@FATURAADET OUTPUT

                    UPDATE #EVRAKADET SET FATURAADET = @FATURAADET WHERE BILDIRIMKOD = @BILDIRIMKOD AND HESAPKOD = @HESAPKOD
                END

                FETCH NEXT FROM X_CURSOR
                INTO
                    @HESAPKOD
                   ,@SATIRTIP
            END

            CLOSE X_CURSOR
            DEALLOCATE X_CURSOR

            FETCH NEXT FROM BILDIRIM_CURSOR
            INTO
                @BILDIRIMKOD
               ,@WHERECLAUSE_STKHAR
               ,@WHERECLAUSE_TCKMSR
               ,@WHERECLAUSE_MHSFIS
        END

        CLOSE BILDIRIM_CURSOR
        DEALLOCATE BILDIRIM_CURSOR

        SELECT
            BF.BILDIRIMKOD AS BILDIRIMKOD
           ,@KONSOLIDESIRKETNO AS KONSOLIDESIRKETNO
           ,'' AS ISLEMKOD
           ,BF.HESAPKOD
           ,ISNULL( CARKRT.UNVAN, '' ) AS UNVAN
           ,ISNULL( CARKRT.UNVAN2, '' ) AS UNVAN2
           ,ISNULL( CARKRT.VERGIDAIRE, '' ) AS VERGIDAIRE
           ,ISNULL((
                       SELECT SUM( R.FATURAADET )FROM #EVRAKADET R WHERE R.BILDIRIMKOD = BF.BILDIRIMKOD AND R.VERGIHESAPNO = CARKRT.VERGIHESAPNO
                   )
                  ,0
                  ) AS FATURAADET
           ,( CASE @YUVARLA
                  WHEN 1 THEN CAST(FLOOR( BF.MATRAH ) AS NUMERIC(25, 6))
                  ELSE BF.MATRAH
              END
            ) AS MATRAH
           ,( CASE @YUVARLA
                  WHEN 1 THEN CAST(FLOOR( BF.KDVTUTAR ) AS NUMERIC(25, 6))
                  ELSE BF.KDVTUTAR
              END
            ) AS KDVTUTAR
           ,BF.KDVORAN AS KDVORAN
           ,BF.KDVKESINTIORAN
           ,BF.KDVKESINTI
           ,ISNULL((
                       SELECT SUM( R.CARIBAKIYE )FROM #EVRAKADET R WHERE R.BILDIRIMKOD = BF.BILDIRIMKOD AND R.VERGIHESAPNO = CARKRT.VERGIHESAPNO
                   )
                  ,0
                  ) AS CARIBAKIYE
           ,( CASE dbo.FNAPP_VALIDATE_TCKN( CARKRT.VERGIHESAPNO )
                  WHEN 1 THEN ''
                  ELSE ( CASE
                             WHEN
                             (
                                 SUBSTRING( VERGIHESAPNO, 1, 10 ) = '1111111111'
                                 OR SUBSTRING( VERGIHESAPNO, 1, 10 ) = '2222222222'
                             ) THEN SUBSTRING( VERGIHESAPNO, 1, 10 )
                             ELSE VERGIHESAPNO
                         END
                       )
              END
            ) AS VERGIHESAPNO
           ,( CASE dbo.FNAPP_VALIDATE_TCKN( CARKRT.VERGIHESAPNO )
                  WHEN 1 THEN ISNULL( CARKRT.VERGIHESAPNO, '' )
                  ELSE ''
              END
            ) AS TCKIMLIKNO
           ,( CASE ISNULL( CARKRT.ULKEKOD, '' )
                  WHEN '' THEN '052'
                  ELSE CARKRT.ULKEKOD
              END
            ) AS ULKEKOD
           ,CARKRT.ULKEKOD AS ULKEKOD
           ,ULKEAD = ISNULL((
                                SELECT TOP 1 R.ULKEAD FROM ULKKRT R WHERE R.ULKEKOD = CARKRT.ULKEKOD
                            )
                           ,''
                           )
           ,CARKRT.FATURAADRES1
           ,CARKRT.FATURAADRES2
           ,CARKRT.FATURAADRES3
           ,CARKRT.FATURAADRES4
           ,CARKRT.FATURAADRES5
           ,CARKRT.TELEFON1
           ,CARKRT.TELEFON2
           ,CARKRT.TELEFON3
           ,CARKRT.TELEFON4
           ,CARKRT.TELEFON5
           ,CARKRT.FAX1
           ,CARKRT.FAX2
           ,CARKRT.FAX3
           ,CARKRT.FAX4
           ,CARKRT.FAX5
           ,CARKRT.EMAIL1
           ,CARKRT.EMAIL2
           ,CARKRT.EMAIL3
           ,CARKRT.EMAIL4
           ,CARKRT.EMAIL5
           ,( ISNULL( CARKRT.UNVAN, '' ) + ' ' + ISNULL( CARKRT.UNVAN2, '' )) AS CARKRT_UNVAN
           ,@DONEMYIL AS DONEMYIL
           ,@DONEMBASAY AS DONEMBASAY
           ,@DONEMBITAY AS DONEMBITAY
           ,CAST('' AS VARCHAR(30)) AS BELGENO
           ,CAST(0 AS SMALLDATETIME) AS BELGETARIH
           ,0 AS ISLEMTUR
           ,CARKRT.MKOD1
        FROM
        (
            SELECT
                BILDIRIMKOD
               ,HESAPKOD
               ,KDVORAN
               ,KDVKESINTIORAN
               ,SUM( MATRAH ) AS MATRAH
               ,SUM( KDVTUTAR ) AS KDVTUTAR
               ,SUM( KDVKESINTI ) AS KDVKESINTI
            FROM #BILDIRIMFORM
            GROUP BY
                BILDIRIMKOD
               ,HESAPKOD
               ,KDVORAN
               ,KDVKESINTIORAN
        ) BF
        LEFT OUTER JOIN
        ( SELECT * FROM dbo.YEK_VW_BLDPRM_CARKRT ) CARKRT ON ( CARKRT.HESAPKOD = BF.HESAPKOD )
        ORDER BY
            BF.BILDIRIMKOD
           ,BF.HESAPKOD
    END
GO