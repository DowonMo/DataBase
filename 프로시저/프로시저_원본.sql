CREATE OR REPLACE PROCEDURE EDU.SP_MT_ORD_RSLT(
v_base_month IN  VARCHAR2
)
IS 
	v_row_chk  INTEGER;  -- 마트테이블 내에 작업월 데이터 유무 Check(재작업시 삭제용도)
    v_row_chk2 INTEGER;  -- 작업할 대상 데이터가 있는지 Check
    v_row_cnt  INTEGER;
BEGIN
	
	DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');      
    -- 작업월 데이터 유무 Check  
    SELECT (  
    			SELECT ORD_MT     
			      FROM EDU.TB_MT_ORD_RSLT
			     WHERE ORD_MT = v_base_month
			       AND ROWNUM = 1
		   )
	  INTO v_row_chk
	  FROM DUAL;
	
	-- 재작업 유무 Check
    IF v_row_chk IS NOT NULL THEN
		DELETE FROM EDU.TB_MT_ORD_RSLT WHERE ORD_MT = v_base_month ;	
    	DBMS_OUTPUT.PUT_LINE(v_base_month || '월 데이터가 이미 존재하여 삭제하였습니다.');
	END IF;

	-- 당월 작업대상 데이터 존재유무 Check
	SELECT 1
	  INTO v_row_chk2
	  FROM EDU.ORDERS
     WHERE ORDER_DATE_VC LIKE CONCAT(v_base_month, '%')
       AND ROWNUM = 1 ;	
	
    -- 작업월 Data 입력
	INSERT INTO EDU.TB_MT_ORD_RSLT
	SELECT 
                v_base_month                      AS ORD_MT
              , T2.CATEGORY_ID 
              , T3.CATEGORY_NAME 
              , T1.PRODUCT_ID
              , T2.PRODUCT_NAME 
              , SUM(T1.QUANTITY)                  AS ORD_CNT
              , SUM(T1.QUANTITY * T1.UNIT_PRICE)  AS ORD_AMT
              , SYSDATE
           FROM EDU.ORDER_ITEMS T1
                                     INNER JOIN EDU.PRODUCTS T2
                                             ON T1.PRODUCT_ID  = T2.PRODUCT_ID 
                                     INNER JOIN EDU.PRODUCT_CATEGORIES T3
                                             ON T2.CATEGORY_ID = T3.CATEGORY_ID 
                                     INNER JOIN EDU.ORDERS   T4
                                             ON T1.ORDER_ID    = T4.ORDER_ID
          WHERE T4.ORDER_DATE_VC LIKE CONCAT(v_base_month, '%')
          GROUP BY 
                T2.CATEGORY_ID 
              , T3.CATEGORY_NAME 
              , T1.PRODUCT_ID
              , T2.PRODUCT_NAME 
              , v_base_month ;
    
    -- 작업월 Data건수 Check
    v_row_cnt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE(v_base_month || '월 작업이 완료되었습니다(입력건수: ' || v_row_cnt || '건)');
    
    COMMIT;   

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(v_base_month || '월에 해당하는 데이터가 없습니다. 확인하시기 바랍니다.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('실행오류가 발생했습니다.(에러코드: ' || SQLERRM || ')');

END SP_MT_ORD_RSLT;