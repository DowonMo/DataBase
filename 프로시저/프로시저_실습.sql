-- EDU.TB_MT_ORD_RSLT definition

CREATE TABLE "EDU07"."TB_MT_ORD_RSLT" 
   (	"ORD_MT" CHAR(6) NOT NULL ENABLE, 
	"CATEGORY_ID" NUMBER NOT NULL ENABLE, 
	"CATEGORY_NAME" VARCHAR2(255) NOT NULL ENABLE, 
	"PRODUCT_ID" NUMBER(12,0) NOT NULL ENABLE, 
	"PRODUCT_NAME" VARCHAR2(255) NOT NULL ENABLE, 
	"ORD_CNT" NUMBER, 
	"ORD_AMT" NUMBER, 
	"ETL_JOB_DT" DATE
   ) SEGMENT CREATION IMMEDIATE 
  PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255 
 NOCOMPRESS LOGGING
  STORAGE(INITIAL 65536 NEXT 1048576 MINEXTENTS 1 MAXEXTENTS 2147483645
  PCTINCREASE 0 FREELISTS 1 FREELIST GROUPS 1
  BUFFER_POOL DEFAULT FLASH_CACHE DEFAULT CELL_FLASH_CACHE DEFAULT)
  TABLESPACE "USERS" ;

COMMENT ON TABLE EDU.TB_MT_ORD_RSLT IS '월별상품주문실적';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.ORD_MT IS '주문월';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.CATEGORY_ID IS '카테고리ID';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.CATEGORY_NAME IS '카테고리명';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.PRODUCT_ID IS '상품ID';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.PRODUCT_NAME IS '상품명';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.ORD_CNT IS '상품주문건수';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.ORD_AMT IS '상품주문금액(수량*단가)';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.ETL_JOB_DT IS '작업일자';

-- 주문월/카테고리ID/카테고리명/상품ID/상품명/당월주문건수/누적주문건수/당월주문금액/누적주문금액

CREATE VIEW ASSIGNMENT_V2 AS
SELECT
    ORD_MT AS 주문월,
    CATEGORY_ID AS 카테고리ID,
    CATEGORY_NAME AS 카테고리명,
    PRODUCT_ID AS 상품ID,
    PRODUCT_NAME AS 상품명,
    QUANTITY AS 당월주문건수,
    SUM(QUANTITY) OVER (PARTITION BY ORD_MT, CATEGORY_ID, PRODUCT_ID ORDER BY ORD_MT
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 누적주문건수,
    ORD_AMT AS 당월주문금액,
    SUM(ORD_AMT) OVER (PARTITION BY ORD_MT, CATEGORY_ID, PRODUCT_ID ORDER BY ORD_MT
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS 누적주문금액
FROM (
   SELECT
      SUBSTR(T1.ORDER_DATE_VC,1,6) AS ORD_MT,
      T4.CATEGORY_ID AS CATEGORY_ID,
      T4.CATEGORY_NAME AS CATEGORY_NAME,
      T3.PRODUCT_ID AS PRODUCT_ID,
      T3.PRODUCT_NAME AS PRODUCT_NAME,
      SUM(T2.QUANTITY) AS QUANTITY,
      SUM(T2.QUANTITY * T2.UNIT_PRICE) AS ORD_AMT
   FROM ORDERS T1
	    INNER JOIN ORDER_ITEMS T2 
	        ON T1.ORDER_ID = T2.ORDER_ID
	    INNER JOIN PRODUCTS T3
	        ON T2.PRODUCT_ID = T3.PRODUCT_ID
	    INNER JOIN PRODUCT_CATEGORIES T4
	        ON T3.CATEGORY_ID = T4.CATEGORY_ID
   WHERE 1=1
   	AND SUBSTR(T1.ORDER_DATE_VC,1,6) LIKE '2024%'
   GROUP BY 
      SUBSTR(T1.ORDER_DATE_VC,1,6),
      T4.CATEGORY_ID,
      T4.CATEGORY_NAME,
      T3.PRODUCT_ID,
      T3.PRODUCT_NAME
)
ORDER BY 1, 2, 4;




CREATE OR REPLACE PROCEDURE SP_MT_ORD_RSLT(
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
	 
	-- AND ROWNUM = 1을 쓴 이유는 속도와 효율성 때문. 어쨋든 이 스칼라 쿼리는 데이터 유무만 확인하는 거다. 전체 데이터를 확인할 필요 없다. 
	-- 첫 번째 것만 가져와서 없으면 중복이 없는 거고 있으면 확인해서 처리하는거고. 일단 중복이 없다면 NULL이 나오는 거니까. 
	-- 만약 이 확인 단계에서 스칼라를 쓰지 않으면 SELECT값이 저 밑의 EXCEPTIOM으로 넘어간다. 그래서 스칼라로 SELECT 값을 잡아버리는 거.
	 
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


/*

DATE함수 사용시 월말(31일)이 아니라 다음월 01일부터 미만으로 검색하는 습관을 들일 것. 몇월에 할지 모르기 때문. 


AND ROWNUM = 1을 쓴 이유는 속도와 효율성 때문. 어쨋든 이 스칼라 쿼리는 데이터 유무만 확인하는 거다. 전체 데이터를 확인할 필요 없다. 첫 번째 것만 가져와서 없으면 중복이 없는 거고 있으면 확인해서 처리하는거고. 일단 중복이 없다면 NULL이 나오는 거니까. 
레이아웃을 먼저 써서 혼자 문제를 내봐라. 

--고객사신용한도구간대별, 회원수

-- 구간대별 월별 회원별 주문건수, 주문금액

-- 월별 회원별 상품카테고리별 주문건수, 주문금액


중급
-- 월별 이용(주문)행태분석 쿼리
#최근 6개월내, 최근 12개월내 연속 이용고객수, 전월이용-당월미이용, 전월미이용-당월이용 전이율분석)
전월에 이용했는데 당월에 이용하지 않은 데이터.

CUSTOMER
한도별 구간대의 주문 건수나 금액. 월별로 뽑아서 월별 트렌드를 확인해보자.

메모리가 쿼리에서 어떻게 수행되는지. 


쿼리를 작성할 땐 현업의 입장에서 데이터와 비즈니스를 먼저 이해한 뒤 구조부터 생각하고 그 구조에 맞춰서 쿼리를 짜야한다.

데이터가 우선이고 쿼리는 나중이다.

참조: SQL 연속 이용 -> 검색

내가 성공해야 하는 이유. 미래의 내 가족과 나의 행복을 위해서. 삶에 만족하기 위해선 가장 많은 시간을 쓰는 직장에서 만족을 얻어야 한다. 직장에서의 만족이 다른 곳에서 생기는 어려움을 포용할 수 있게 해주는 여유가 된다.


		
		
		