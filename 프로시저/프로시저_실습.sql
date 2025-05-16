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

COMMENT ON TABLE EDU.TB_MT_ORD_RSLT IS '������ǰ�ֹ�����';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.ORD_MT IS '�ֹ���';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.CATEGORY_ID IS 'ī�װ�ID';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.CATEGORY_NAME IS 'ī�װ���';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.PRODUCT_ID IS '��ǰID';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.PRODUCT_NAME IS '��ǰ��';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.ORD_CNT IS '��ǰ�ֹ��Ǽ�';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.ORD_AMT IS '��ǰ�ֹ��ݾ�(����*�ܰ�)';
COMMENT ON COLUMN EDU.TB_MT_ORD_RSLT.ETL_JOB_DT IS '�۾�����';

-- �ֹ���/ī�װ�ID/ī�װ���/��ǰID/��ǰ��/����ֹ��Ǽ�/�����ֹ��Ǽ�/����ֹ��ݾ�/�����ֹ��ݾ�

CREATE VIEW ASSIGNMENT_V2 AS
SELECT
    ORD_MT AS �ֹ���,
    CATEGORY_ID AS ī�װ�ID,
    CATEGORY_NAME AS ī�װ���,
    PRODUCT_ID AS ��ǰID,
    PRODUCT_NAME AS ��ǰ��,
    QUANTITY AS ����ֹ��Ǽ�,
    SUM(QUANTITY) OVER (PARTITION BY ORD_MT, CATEGORY_ID, PRODUCT_ID ORDER BY ORD_MT
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS �����ֹ��Ǽ�,
    ORD_AMT AS ����ֹ��ݾ�,
    SUM(ORD_AMT) OVER (PARTITION BY ORD_MT, CATEGORY_ID, PRODUCT_ID ORDER BY ORD_MT
                        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS �����ֹ��ݾ�
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
	v_row_chk  INTEGER;  -- ��Ʈ���̺� ���� �۾��� ������ ���� Check(���۾��� �����뵵)
    v_row_chk2 INTEGER;  -- �۾��� ��� �����Ͱ� �ִ��� Check
    v_row_cnt  INTEGER;
BEGIN
	
	DBMS_OUTPUT.PUT_LINE('-------------------------------------------------');      
    -- �۾��� ������ ���� Check  
    SELECT (  
    			SELECT ORD_MT     
			      FROM EDU.TB_MT_ORD_RSLT
			     WHERE ORD_MT = v_base_month
			       AND ROWNUM = 1
		   )			
	  INTO v_row_chk
	  FROM DUAL;
	 
	-- AND ROWNUM = 1�� �� ������ �ӵ��� ȿ���� ����. ��¶�� �� ��Į�� ������ ������ ������ Ȯ���ϴ� �Ŵ�. ��ü �����͸� Ȯ���� �ʿ� ����. 
	-- ù ��° �͸� �����ͼ� ������ �ߺ��� ���� �Ű� ������ Ȯ���ؼ� ó���ϴ°Ű�. �ϴ� �ߺ��� ���ٸ� NULL�� ������ �Ŵϱ�. 
	-- ���� �� Ȯ�� �ܰ迡�� ��Į�� ���� ������ SELECT���� �� ���� EXCEPTIOM���� �Ѿ��. �׷��� ��Į��� SELECT ���� ��ƹ����� ��.
	 
	-- ���۾� ���� Check
    IF v_row_chk IS NOT NULL THEN
		DELETE FROM EDU.TB_MT_ORD_RSLT WHERE ORD_MT = v_base_month ;	
    	DBMS_OUTPUT.PUT_LINE(v_base_month || '�� �����Ͱ� �̹� �����Ͽ� �����Ͽ����ϴ�.');
	END IF;

	-- ��� �۾���� ������ �������� Check
	SELECT 1
	  INTO v_row_chk2
	  FROM EDU.ORDERS
     WHERE ORDER_DATE_VC LIKE CONCAT(v_base_month, '%')
       AND ROWNUM = 1 ;	
	
    -- �۾��� Data �Է�
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
    
    -- �۾��� Data�Ǽ� Check
    v_row_cnt := SQL%ROWCOUNT;
    DBMS_OUTPUT.PUT_LINE(v_base_month || '�� �۾��� �Ϸ�Ǿ����ϴ�(�Է°Ǽ�: ' || v_row_cnt || '��)');
    
    COMMIT;   

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE(v_base_month || '���� �ش��ϴ� �����Ͱ� �����ϴ�. Ȯ���Ͻñ� �ٶ��ϴ�.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('��������� �߻��߽��ϴ�.(�����ڵ�: ' || SQLERRM || ')');

END SP_MT_ORD_RSLT;


/*

DATE�Լ� ���� ����(31��)�� �ƴ϶� ������ 01�Ϻ��� �̸����� �˻��ϴ� ������ ���� ��. ����� ���� �𸣱� ����. 


AND ROWNUM = 1�� �� ������ �ӵ��� ȿ���� ����. ��¶�� �� ��Į�� ������ ������ ������ Ȯ���ϴ� �Ŵ�. ��ü �����͸� Ȯ���� �ʿ� ����. ù ��° �͸� �����ͼ� ������ �ߺ��� ���� �Ű� ������ Ȯ���ؼ� ó���ϴ°Ű�. �ϴ� �ߺ��� ���ٸ� NULL�� ������ �Ŵϱ�. 
���̾ƿ��� ���� �Ἥ ȥ�� ������ ������. 

--����ſ��ѵ������뺰, ȸ����

-- �����뺰 ���� ȸ���� �ֹ��Ǽ�, �ֹ��ݾ�

-- ���� ȸ���� ��ǰī�װ��� �ֹ��Ǽ�, �ֹ��ݾ�


�߱�
-- ���� �̿�(�ֹ�)���ºм� ����
#�ֱ� 6������, �ֱ� 12������ ���� �̿����, �����̿�-������̿�, �������̿�-����̿� �������м�)
������ �̿��ߴµ� ����� �̿����� ���� ������.

CUSTOMER
�ѵ��� �������� �ֹ� �Ǽ��� �ݾ�. ������ �̾Ƽ� ���� Ʈ���带 Ȯ���غ���.

�޸𸮰� �������� ��� ����Ǵ���. 


������ �ۼ��� �� ������ ���忡�� �����Ϳ� ����Ͻ��� ���� ������ �� �������� �����ϰ� �� ������ ���缭 ������ ¥���Ѵ�.

�����Ͱ� �켱�̰� ������ �����̴�.

����: SQL ���� �̿� -> �˻�

���� �����ؾ� �ϴ� ����. �̷��� �� ������ ���� �ູ�� ���ؼ�. � �����ϱ� ���ؼ� ���� ���� �ð��� ���� ���忡�� ������ ���� �Ѵ�. ���忡���� ������ �ٸ� ������ ����� ������� ������ �� �ְ� ���ִ� ������ �ȴ�.


		
		
		