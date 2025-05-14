/*==================
튜닝 실습
테이블 생성 DDL문
==================*/

-- tuning.급여 definition
CREATE TABLE `급여` (
  `사원번호` int NOT NULL,
  `연봉` int NOT NULL,
  `시작일자` date NOT NULL,
  `종료일자` date NOT NULL,
  `사용여부` char(1) DEFAULT '',
  PRIMARY KEY (`사원번호`,`시작일자`),
  KEY `I_사용여부` (`사용여부`)
) 

-- tuning.부서 definition
CREATE TABLE `부서` (
  `부서번호` char(4) NOT NULL,
  `부서명` varchar(40) NOT NULL,
  `비고` varchar(40) DEFAULT NULL,
  PRIMARY KEY (`부서번호`) USING BTREE,
  UNIQUE KEY `UI_부서명` (`부서명`) USING BTREE
)


-- tuning.부서관리자 definition
CREATE TABLE `부서관리자` (
  `사원번호` int NOT NULL,
  `부서번호` char(4) NOT NULL,
  `시작일자` date NOT NULL,
  `종료일자` date NOT NULL,
  PRIMARY KEY (`사원번호`,`부서번호`) USING BTREE,
  KEY `I_부서번호` (`부서번호`) USING BTREE
)


-- tuning.부서사원_매핑 definition
CREATE TABLE `부서사원_매핑` (
  `사원번호` int NOT NULL,
  `부서번호` char(4) NOT NULL,
  `시작일자` date NOT NULL,
  `종료일자` date NOT NULL,
  PRIMARY KEY (`사원번호`,`부서번호`) USING BTREE,
  KEY `I_부서번호` (`부서번호`) USING BTREE
)


-- tuning.사원 definition
CREATE TABLE `사원` (
  `사원번호` int NOT NULL,
  `생년월일` date NOT NULL,
  `이름` varchar(14) NOT NULL,
  `성` varchar(16) NOT NULL,
  `성별` enum('M','F') NOT NULL,
  `입사일자` date NOT NULL,
  PRIMARY KEY (`사원번호`) USING BTREE,
  KEY `I_입사일자` (`입사일자`) USING BTREE,
  KEY `I_성별_성` (`성별`,`성`) USING BTREE
)


-- tuning.사원출입기록 definition
CREATE TABLE `사원출입기록` (
  `순번` int NOT NULL AUTO_INCREMENT,
  `사원번호` int NOT NULL,
  `입출입시간` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `입출입구분` char(1) NOT NULL,
  `출입문` char(1) DEFAULT NULL,
  `지역` char(1) DEFAULT NULL,
  PRIMARY KEY (`순번`,`사원번호`) USING BTREE,
  KEY `I_지역` (`지역`),
  KEY `I_시간` (`입출입시간`),
  KEY `I_출입문` (`출입문`)
)


-- tuning.직급 definition
CREATE TABLE `직급` (
  `사원번호` int NOT NULL,
  `직급명` varchar(50) NOT NULL,
  `시작일자` date NOT NULL,
  `종료일자` date DEFAULT NULL,
  PRIMARY KEY (`사원번호`,`직급명`,`시작일자`) USING BTREE
)