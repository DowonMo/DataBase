CREATE OR REPLACE PROCEDURE EDU.calculate_average_salary (dept_name IN number) IS
    avg_salary NUMBER;
BEGIN 
    -- 평균 급여를 계산하여 avg_salary 변수에 저장합니다.
    SELECT AVG(sal) 
      INTO avg_salary
      FROM emp
     WHERE DEPTNO = dept_name;
    
    -- 결과를 출력합니다.
    DBMS_OUTPUT.PUT_LINE('부서코드: ' || dept_name || ', Average Salary: ' || ROUND(avg_salary, 2));
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No employees found in the ' || dept_name || ' department.');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error occurred: ' || SQLERRM);
END;