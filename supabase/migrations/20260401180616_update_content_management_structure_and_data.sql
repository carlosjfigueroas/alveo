-- 1. Fix about_us table primary key
ALTER TABLE about_us DROP CONSTRAINT about_us_pkey;
ALTER TABLE about_us ADD PRIMARY KEY (key, company_id);

-- 2. Update existing data in about_us
UPDATE about_us 
SET 
  value_es = REPLACE(value_es, 'Group Adm. C.C.C.P.R.', 'NOMBRE EMPRESA'),
  value_en = REPLACE(value_en, 'Group Adm. C.C.C.P.R.', 'NOMBRE EMPRESA')
WHERE company_id = '417a4ab6-bd36-400e-b71e-84b0c023befa';

-- 3. Update existing data in faqs
UPDATE faqs 
SET 
  answer_es = REPLACE(answer_es, 'Group Adm. C.C.C.P.R.', 'NOMBRE EMPRESA'),
  answer_en = REPLACE(answer_en, 'Group Adm. C.C.C.P.R.', 'NOMBRE EMPRESA'),
  question_es = REPLACE(question_es, 'Group Adm. C.C.C.P.R.', 'NOMBRE EMPRESA'),
  question_en = REPLACE(question_en, 'Group Adm. C.C.C.P.R.', 'NOMBRE EMPRESA')
WHERE company_id = '417a4ab6-bd36-400e-b71e-84b0c023befa';

-- 4. Copy to Demo Company (id: 49bef18f-0021-4f78-904b-d2c8d47439d8)
INSERT INTO about_us (key, value_es, value_en, company_id)
SELECT key, value_es, value_en, '49bef18f-0021-4f78-904b-d2c8d47439d8'
FROM about_us
WHERE company_id = '417a4ab6-bd36-400e-b71e-84b0c023befa'
ON CONFLICT (key, company_id) DO NOTHING;

INSERT INTO faqs (question_es, answer_es, question_en, answer_en, sort_order, company_id)
SELECT question_es, answer_es, question_en, answer_en, sort_order, '49bef18f-0021-4f78-904b-d2c8d47439d8'
FROM faqs
WHERE company_id = '417a4ab6-bd36-400e-b71e-84b0c023befa';
;
