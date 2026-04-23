-- ============================================================================
-- M2b 페이즈 4-1: regions.environment_tags 컬럼 추가 + 데이터 채우기
-- ============================================================================
-- 생성일: 2026-04-23
-- 마일스톤: M2b (엘리트의 시대)
-- 출처 명세: Docs/spec/[spec]20260423_m2b-4-1-region-environment-tags.md
-- 데이터 소스: Docs/content-data/[region-environment-tag]20260423_m2b-regions.csv
-- 멱등성: ADD COLUMN IF NOT EXISTS + 재실행 시 동일 값으로 UPDATE
-- ============================================================================

BEGIN;

-- §1. environment_tags JSONB 컬럼 추가
ALTER TABLE regions
  ADD COLUMN IF NOT EXISTS environment_tags JSONB NOT NULL DEFAULT '[]'::jsonb;

-- §2. 199개 리전 환경 태그 일괄 UPDATE
UPDATE regions AS r
SET environment_tags = v.tags::jsonb
FROM (VALUES
  (1,'["plains"]'),(2,'["desert"]'),(3,'["plains"]'),(4,'["mountain"]'),
  (5,'["forest"]'),(6,'["plains"]'),(7,'["underground"]'),(8,'["ruins"]'),
  (9,'["forest"]'),(10,'["forest"]'),(11,'["underground"]'),(12,'["plains"]'),
  (13,'["mountain"]'),(14,'["plains"]'),(15,'["plains"]'),(16,'["mountain"]'),
  (17,'["ruins","underground"]'),(18,'["mountain"]'),(19,'["ruins"]'),(20,'["forest"]'),
  (21,'["mountain"]'),(22,'["desert"]'),(23,'["forest"]'),(24,'["mountain"]'),
  (25,'["plains"]'),(26,'["ruins"]'),(27,'["plains"]'),(28,'["mountain"]'),
  (29,'["plains"]'),(30,'["forest"]'),(31,'["plains"]'),(32,'["ruins"]'),
  (33,'["plains"]'),(34,'["plains"]'),(35,'["mountain"]'),(36,'["ruins","underground"]'),
  (37,'["forest"]'),(38,'["ruins"]'),(39,'["plains"]'),(40,'["forest"]'),
  (41,'["plains"]'),(42,'["plains"]'),(43,'["plains"]'),(44,'["desert"]'),
  (45,'["plains"]'),(46,'["mountain"]'),(47,'["mountain"]'),(48,'["underground"]'),
  (49,'["ruins"]'),(50,'["ruins"]'),(51,'["ruins"]'),(52,'["ruins"]'),
  (53,'["mountain"]'),(54,'["forest"]'),(55,'["mountain"]'),(56,'["desert"]'),
  (57,'["mountain"]'),(58,'["mountain"]'),(59,'["mountain"]'),(60,'["ruins","underground"]'),
  (61,'["ruins","underground"]'),(62,'["ruins","underground"]'),(63,'["forest"]'),(64,'["plains"]'),
  (65,'["ruins"]'),(66,'["desert"]'),(67,'["plains"]'),(68,'["ruins"]'),
  (69,'["mountain"]'),(70,'["plains"]'),(71,'["plains"]'),(72,'["ruins"]'),
  (73,'["plains"]'),(74,'["forest"]'),(75,'["forest"]'),(76,'["plains"]'),
  (77,'["plains"]'),(78,'["ruins","underground"]'),(79,'["ruins"]'),(80,'["plains"]'),
  (81,'["desert"]'),(82,'["forest"]'),(83,'["forest"]'),(84,'["ruins","underground"]'),
  (85,'["plains"]'),(86,'["ruins","underground"]'),(87,'["ruins"]'),(88,'["mountain"]'),
  (89,'["plains"]'),(90,'["plains"]'),(91,'["mountain"]'),(92,'["mountain"]'),
  (93,'["forest"]'),(94,'["ruins","underground"]'),(95,'["plains"]'),(96,'["plains"]'),
  (97,'["plains"]'),(98,'["plains"]'),(99,'["coast"]'),(100,'["plains"]'),
  (101,'["mountain"]'),(102,'["underground"]'),(103,'["ruins"]'),(104,'["forest"]'),
  (105,'["plains"]'),(106,'["ruins"]'),(107,'["desert"]'),(108,'["plains"]'),
  (109,'["mountain"]'),(110,'["coast"]'),(111,'["coast"]'),(112,'["forest"]'),
  (113,'["forest"]'),(114,'["underground"]'),(115,'["desert"]'),(116,'["ruins"]'),
  (117,'["mountain"]'),(118,'["coast"]'),(119,'["coast"]'),(120,'["coast"]'),
  (121,'["ruins"]'),(122,'["ruins"]'),(123,'["forest"]'),(124,'["desert"]'),
  (125,'["mountain"]'),(126,'["forest"]'),(127,'["coast"]'),(128,'["forest"]'),
  (129,'["coast"]'),(130,'["mountain"]'),(131,'["underground"]'),(132,'["coast"]'),
  (133,'["forest"]'),(134,'["mountain"]'),(135,'["ruins"]'),(136,'["desert"]'),
  (137,'["underground"]'),(138,'["coast"]'),(139,'["forest"]'),(140,'["ruins"]'),
  (141,'["mountain"]'),(142,'["coast"]'),(143,'["mountain"]'),(144,'["forest"]'),
  (145,'["forest"]'),(146,'["swamp"]'),(147,'["swamp"]'),(148,'["desert"]'),
  (149,'["swamp"]'),(150,'["mountain"]'),(151,'["swamp"]'),(152,'["plains"]'),
  (153,'["swamp"]'),(154,'["desert"]'),(155,'["mountain"]'),(156,'["mountain"]'),
  (157,'["mountain"]'),(158,'["desert"]'),(159,'["ruins"]'),(160,'["underground"]'),
  (161,'["coast"]'),(162,'["underground"]'),(163,'["coast"]'),(164,'["swamp"]'),
  (165,'["coast"]'),(166,'["mountain"]'),(167,'["plains"]'),(168,'["swamp"]'),
  (169,'["ruins"]'),(170,'["desert"]'),(171,'["ruins"]'),(172,'["mountain"]'),
  (173,'["underground"]'),(174,'["ruins"]'),(175,'["swamp"]'),(176,'["ruins"]'),
  (177,'["coast"]'),(178,'["swamp"]'),(179,'["mountain"]'),(180,'["mountain"]'),
  (181,'["plains"]'),(182,'["ruins"]'),(183,'["ruins"]'),(184,'["underground"]'),
  (185,'["coast"]'),(186,'["plains"]'),(187,'["plains"]'),(188,'["plains"]'),
  (189,'["plains"]'),(190,'["coast"]'),(191,'["underground"]'),(192,'["ruins"]'),
  (193,'["coast"]'),(194,'["swamp"]'),(195,'["swamp"]'),(196,'["underground"]'),
  (197,'["underground"]'),(198,'["desert"]'),(199,'["underground"]')
) AS v(region_id, tags)
WHERE r.id = v.region_id;

-- §3. data_versions 버전 갱신 (Flutter 앱 재동기화 트리거)
UPDATE data_versions SET version = 3 WHERE table_name = 'regions';

COMMIT;
