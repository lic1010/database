-- =========================================================================
-- 1. 實體資料表建立 (Table Creation with Constraints & Domains)
-- =========================================================================

-- 1.1 帳號安全憑證表
CREATE TABLE Account (
    account_Id CHAR(10) NOT NULL,
    username VARCHAR(50) NOT NULL,
    phoneNumber VARCHAR(20) NOT NULL,
    email VARCHAR(100) NOT NULL,
    passwordHash CHAR(60) NOT NULL,
    CONSTRAINT PK_Account PRIMARY KEY (account_Id),
    CONSTRAINT UQ_Account_Username UNIQUE (username),
    CONSTRAINT UQ_Account_Email UNIQUE (email),
    CONSTRAINT chk_account_id_domain CHECK (
        LENGTH(account_Id) = 10 
        AND account_Id ~ '^a[0-9]{9}$'
    ),
    CONSTRAINT chk_account_email_format CHECK (
        email ~ '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'
    )
);

-- 1.2 成員業務行為表
CREATE TABLE Member (
    member_id CHAR(10) NOT NULL,
    accountid CHAR(10) NOT NULL,
    city VARCHAR(20) NOT NULL,
    address_line VARCHAR(100) NOT NULL,
    zipcode VARCHAR(10) NOT NULL,
    CONSTRAINT PK_Member PRIMARY KEY (member_id),
    CONSTRAINT FK_Member_Account FOREIGN KEY (accountid) REFERENCES Account(account_Id) ON DELETE CASCADE,
    CONSTRAINT chk_member_id_domain CHECK (
        LENGTH(member_id) = 10 
        AND member_id ~ '^m[0-9]{9}$'
    )
);

-- 1.3 團購群組活動表
CREATE TABLE GroupBuyGroup (
    group_id CHAR(10) NOT NULL,
    creatorId CHAR(10) NOT NULL,
    groupName VARCHAR(50) NOT NULL,
    creationDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    deadlineDate TIMESTAMP NOT NULL,
    description VARCHAR(255),
    state CHAR(1) NOT NULL DEFAULT '1', -- '0':邏輯下架/取消, '1':進行中, '2':已結團
    CONSTRAINT PK_GroupBuyGroup PRIMARY KEY (group_id),
    CONSTRAINT FK_GroupBuyGroup_Member FOREIGN KEY (creatorId) REFERENCES Member(member_id),
    CONSTRAINT chk_group_id_domain CHECK (
        LENGTH(group_id) = 10 
        AND group_id ~ '^g[0-9]{9}$'
    ),
    CONSTRAINT chk_group_state CHECK (state IN ('0', '1', '2'))
);

-- 1.4 社群討論行銷貼文表
CREATE TABLE DiscussionPost (
    postid_id CHAR(10) NOT NULL,
    memberId CHAR(10) NOT NULL,
    groupid CHAR(10) NOT NULL,
    postDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    text_content TEXT NOT NULL,
    CONSTRAINT PK_DiscussionPost PRIMARY KEY (postid_id),
    CONSTRAINT FK_DiscussionPost_Member FOREIGN KEY (memberId) REFERENCES Member(member_id),
    CONSTRAINT FK_DiscussionPost_Group FOREIGN KEY (groupid) REFERENCES GroupBuyGroup(group_id),
    CONSTRAINT chk_post_id_domain CHECK (
        LENGTH(postid_id) = 10 
        AND postid_id ~ '^p[0-9]{9}$'
    )
);

-- 1.5 優惠券維護表
CREATE TABLE Voucher (
    voucher_id CHAR(10) NOT NULL,
    voucherCode VARCHAR(20) NOT NULL,
    validFrom TIMESTAMP NOT NULL,
    validUntil TIMESTAMP NOT NULL,
    CONSTRAINT PK_Voucher PRIMARY KEY (voucher_id),
    CONSTRAINT UQ_Voucher_Code UNIQUE (voucherCode),
    CONSTRAINT chk_voucher_id_domain CHECK (
        LENGTH(voucher_id) = 10 
        AND voucher_id ~ '^v[0-9]{9}$'
    ),
    CONSTRAINT chk_voucher_date CHECK (validUntil > validFrom)
);

-- 1.6 核心訂單主檔表
CREATE TABLE "Order" (
    order_Id CHAR(10) NOT NULL,
    memberid CHAR(10) NOT NULL,
    groupid CHAR(10) NOT NULL,
    voucherId CHAR(10),
    totalAmount INT NOT NULL,
    orderDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status CHAR(1) NOT NULL DEFAULT '1', -- '0':邏輯刪除/取消, '1':處理中, '2':已完成
    CONSTRAINT PK_Order PRIMARY KEY (order_Id),
    CONSTRAINT FK_Order_Member FOREIGN KEY (memberid) REFERENCES Member(member_id),
    CONSTRAINT FK_Order_Group FOREIGN KEY (groupid) REFERENCES GroupBuyGroup(group_id),
    CONSTRAINT FK_Order_Voucher FOREIGN KEY (voucherId) REFERENCES Voucher(voucher_id),
    CONSTRAINT chk_order_id_domain CHECK (
        LENGTH(order_Id) = 10 
        AND order_Id ~ '^o[0-9]{9}$'
    ),
    CONSTRAINT chk_order_status CHECK (status IN ('0', '1', '2')),
    CONSTRAINT chk_order_amount CHECK (totalAmount >= 0)
);

-- 1.7 商品主檔表
CREATE TABLE Product (
    product_id CHAR(10) NOT NULL,
    productName VARCHAR(50) NOT NULL,
    basePrice INT NOT NULL,
    minPurchaseQty INT NOT NULL DEFAULT 1,
    stockAvailable INT NOT NULL DEFAULT 0,
    CONSTRAINT PK_Product PRIMARY KEY (product_id),
    CONSTRAINT chk_product_id_domain CHECK (
        LENGTH(product_id) = 10 
        AND product_id ~ '^pro[0-9]{7}$'
    ),
    CONSTRAINT chk_product_price CHECK (basePrice >= 0),
    CONSTRAINT chk_product_qty CHECK (minPurchaseQty > 0),
    CONSTRAINT chk_product_stock CHECK (stockAvailable >= 0)
);

-- 1.8 交易歷史規格快照表 (與 Order & Product 複合關聯)
CREATE TABLE ProductSpecification (
    spec_id CHAR(10) NOT NULL,
    orderid CHAR(10) NOT NULL,
    productid CHAR(10) NOT NULL,
    group_name VARCHAR(20) NOT NULL,
    option_code VARCHAR(30) NOT NULL,
    option_name VARCHAR(100) NOT NULL,
    CONSTRAINT PK_ProductSpecification PRIMARY KEY (spec_id),
    CONSTRAINT FK_Spec_Order FOREIGN KEY (orderid) REFERENCES "Order"(order_Id) ON DELETE CASCADE,
    CONSTRAINT FK_Spec_Product FOREIGN KEY (productid) REFERENCES Product(product_id),
    CONSTRAINT chk_spec_id_domain CHECK (
        LENGTH(spec_id) = 10 
        AND spec_id ~ '^s[0-9]{9}$'
    )
);

-- 1.9 金流第三方扣款紀錄表
CREATE TABLE Payment (
    payment_id CHAR(12) NOT NULL,
    orderid CHAR(10) NOT NULL,
    paymentMethod CHAR(1) NOT NULL, -- '0':信用卡, '1':LINE Pay, '2':ATM
    paymentDate TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amountPaid INT NOT NULL,
    transactionid VARCHAR(50) NOT NULL,
    CONSTRAINT PK_Payment PRIMARY KEY (payment_id),
    CONSTRAINT UQ_Payment_Order UNIQUE (orderid),
    CONSTRAINT UQ_Payment_Transaction UNIQUE (transactionid),
    CONSTRAINT FK_Payment_Order FOREIGN KEY (orderid) REFERENCES "Order"(order_Id),
    CONSTRAINT chk_payment_id_domain CHECK (
        LENGTH(payment_id) = 12 
        AND payment_id ~ '^t[0-9]{11}$'
    ),
    CONSTRAINT chk_payment_method CHECK (paymentMethod IN ('0', '1', '2')),
    CONSTRAINT chk_payment_amount CHECK (amountPaid > 0)
);


-- =========================================================================
-- 2. 10 筆系統運轉測試真實資料填入 (Data Insertion)
-- =========================================================================

-- 2.1 Account
INSERT INTO Account (account_Id, username, phoneNumber, email, passwordHash) VALUES
('a260100001', 'user_tommy', '0912345678', 'tommy@nhust.edu.tw', '$2a$12$K3v9xHjY6m7bZ8qL9pQnUe1r2t3y4u5i6o7p8a9s0d1f2g3h4j5k'),
('a260100002', 'leader_alice', '0923456789', 'alice_group@gmail.com', '$2a$12$X7m2b8qL9pQnUe1r2t3y4u5i6o7p8a9s0d1f2g3h4j5k6l7m8n9o'),
('a260100003', 'user_bob', '0934567890', 'bob99@yahoo.com.tw', '$2a$12$P9qL9pQnUe1r2t3y4u5i6o7p8a9s0d1f2g3h4j5k6l7m8n9o0p1q'),
('a260100004', 'leader_carol', '0945678901', 'carol_shop@gmail.com', '$2a$12$QnUe1r2t3y4u5i6o7p8a9s0d1f2g3h4j5k6l7m8n9o0p1q2r3s4t'),
('a260100005', 'user_david', '0956789012', 'david_lee@gmail.com', '$2a$12$Ue1r2t3y4u5i6o7p8a9s0d1f2g3h4j5k6l7m8n9o0p1q2r3s4t5u'),
('a260100006', 'leader_emily', '0967890123', 'emily_select@gmail.com', '$2a$12$1r2t3y4u5i6o7p8a9s0d1f2g3h4j5k6l7m8n9o0p1q2r3s4t5u6v'),
('a260100007', 'user_frank', '0978901234', 'frank_lin@gmail.com', '$2a$12$3y4u5i6o7p8a9s0d1f2g3h4j5k6l7m8n9o0p1q2r3s4t5u6v7w8x'),
('a260100008', 'user_grace', '0989012345', 'grace_wu@gmail.com', '$2a$12$5i6o7p8a9s0d1f2g3h4j5k6l7m8n9o0p1q2r3s4t5u6v7w8x9y0z'),
('a260100009', 'user_henry', '0990123456', 'henry_chang@gmail.com', '$2a$12$7p8a9s0d1f2g3h4j5k6l7m8n9o0p1q2r3s4t5u6v7w8x9y0z1a2b'),
('a260100010', 'user_iris', '0911223344', 'iris_wang@gmail.com', '$2a$12$9s0d1f2g3h4j5k6l7m8n9o0p1q2r3s4t5u6v7w8x9y0z1a2b3c4d');

-- 2.2 Member
INSERT INTO Member (member_id, accountid, city, address_line, zipcode) VALUES
('m260100001', 'a260100001', '雲林縣', '虎尾鎮文化路64號', '632'),
('m260100002', 'a260100002', '台北市', '大安區羅斯福路四段1號', '106'),
('m260100003', 'a260100003', '雲林縣', '斗六市大學路三段123號', '640'),
('m260100004', 'a260100004', '台中市', '西屯區台灣大道四段1727號', '407'),
('m260100005', 'a260100005', '高雄市', '岡山區大仁路1號', '820'),
('m260100006', 'a260100006', '新北市', '板橋區文化路一段50號', '220'),
('m260100007', 'a260100007', '台南市', '東區大學路1號', '701'),
('m260100008', 'a260100008', '雲林縣', '虎尾鎮民主路100號', '632'),
('m260100009', 'a260100009', '台北市', '信義區信義路五段7號', '110'),
('m260100010', 'a260100010', '台中市', '北區三民路三段129號', '404');

-- 2.3 GroupBuyGroup
INSERT INTO GroupBuyGroup (group_id, creatorId, groupName, creationDate, deadlineDate, description, state) VALUES
('g260100001', 'm260100002', '大甲媽祖聯名爆米花團', '2026-05-20 10:00:00', '2026-06-25 23:59:59', '在地好滋味，限時成團！', '1'),
('g260100002', 'm260100004', '高質感純棉極簡T恤小隊', '2026-05-22 14:30:00', '2026-06-28 18:00:00', '多色可選，夏日必備精選。', '1'),
('g260100003', 'm260100006', '辦公室團購第一名手工蛋捲', '2026-05-25 09:00:00', '2026-06-30 20:00:00', '秒殺級手工蛋捲，團購特別價。', '1'),
('g260100004', 'm260100002', '不沾鍋廚具限時特惠組', '2025-12-01 10:00:00', '2025-12-30 23:59:59', '過期歷史資料測試團', '2'),
('g260100005', 'm260100004', '科技宅必備多功能側背包', '2026-06-01 12:00:00', '2026-07-05 23:59:59', '防潑水大容量設計。', '1'),
('g260100006', 'm260100006', '低卡高蛋白燕麥脆片團', '2026-06-05 15:00:00', '2026-07-10 23:59:59', '健康飽足，健身族群首選。', '1'),
('g260100007', 'm260100002', '頂級精品濾掛咖啡包', '2026-06-10 08:30:00', '2026-07-15 12:00:00', '接單現磨，濃郁香醇。', '1'),
('g260100008', 'm260100004', '抗UV防風超輕量晴雨傘', '2026-06-12 11:00:00', '2026-07-20 23:59:59', '夏日抗曬利器，超輕好收納。', '1'),
('g260100009', 'm260100006', '夏季透氣涼感冰絲長褲', '2026-06-14 16:20:00', '2026-07-25 23:59:59', '極致涼感，擺脫夏日悶熱。', '1'),
('g260100010', 'm260100002', '日式無油烘焙堅果家庭號', '2026-06-15 19:00:00', '2026-07-30 23:59:59', '大包裝吃更久，低溫烘焙最健康。', '1');

-- 2.4 DiscussionPost
INSERT INTO DiscussionPost (postid_id, memberId, groupid, postDate, text_content) VALUES
('p260100001', 'm260100002', 'g260100001', '2026-05-20 10:05:00', '大家敲碗的爆米花開團囉！趕快跟上！'),
('p260100002', 'm260100004', 'g260100002', '2026-05-22 14:40:00', '這款純棉短T超級舒服，穿過就回不去了。'),
('p260100003', 'm260100006', 'g260100003', '2026-05-25 09:15:00', '在地人才知道的手工蛋捲，辦公室下午茶首選！'),
('p260100004', 'm260100002', 'g260100004', '2025-12-01 10:05:00', '歷史過期不沾鍋促銷貼文測試。'),
('p260100005', 'm260100004', 'g260100005', '2026-06-01 12:10:00', '這款包工程師必備，夾層超多，裝筆電很安全。'),
('p260100006', 'm260100006', 'g260100006', '2026-06-05 15:15:00', '控糖減肥也能吃的零食！高纖低卡超美味。'),
('p260100007', 'm260100002', 'g260100007', '2026-06-10 08:40:00', '每天早上一杯職人濾掛，精神百倍。'),
('p260100008', 'm260100004', 'g260100008', '2026-06-12 11:15:00', '梅雨季防風、大太陽防曬，一小把搞定。'),
('p260100009', 'm260100006', 'g260100009', '2026-06-14 16:30:00', '穿上體感溫度直接降3度，夏天穿長褲也不怕悶。'),
('p260100010', 'm260100002', 'g260100010', '2026-06-15 19:10:00', '給全家人最健康的無鹽堅果，大包裝最划算。');

-- 2.5 Product
INSERT INTO Product (product_id, productName, basePrice, minPurchaseQty, stockAvailable) VALUES
('pro2600001', '聯名焦糖爆米花', 150, 2, 500),
('pro2600002', '極簡重磅純棉短T', 390, 1, 300),
('pro2600003', '經典原味手工蛋捲', 250, 1, 200),
('pro2600004', '不沾平底鍋28cm', 990, 1, 50),
('pro2600005', '防潑水機能側背包', 850, 1, 120),
('pro2600006', '高蛋白巧克力燕麥脆片', 180, 2, 400),
('pro2600007', '耶加雪菲濾掛咖啡(10入)', 320, 1, 150),
('pro2600008', '超輕量碳纖維晴雨傘', 450, 1, 250),
('pro2600009', '冰絲涼感機能長褲', 590, 1, 180),
('pro2600010', '綜合低溫烘焙堅果(500g)', 480, 1, 300);

-- 2.6 Voucher
INSERT INTO Voucher (voucher_id, voucherCode, validFrom, validUntil) VALUES
('v260100001', 'WELCOME2026', '2026-01-01 00:00:00', '2026-12-31 23:59:59'),
('v260100002', 'GROUP50', '2026-05-01 00:00:00', '2026-07-31 23:59:59'),
('v260100003', 'EAT88', '2026-05-15 00:00:00', '2026-06-30 23:59:59'),
('v260100004', 'SUMMER100', '2026-06-01 00:00:00', '2026-08-31 23:59:59'),
('v260100005', 'HEALTHYGO', '2026-06-01 00:00:00', '2026-07-15 23:59:59'),
('v260100006', 'COFFEETIME', '2026-06-01 00:00:00', '2026-07-31 23:59:59'),
('v260100007', 'RAINYDAY', '2026-06-10 00:00:00', '2026-08-31 23:59:59'),
('v260100008', 'COOLSUMMER', '2026-06-10 00:00:00', '2026-07-31 23:59:59'),
('v260100009', 'NUTSFAMILY', '2026-06-15 00:00:00', '2026-08-15 23:59:59'),
('v260100010', 'VIPONLY', '2026-01-01 00:00:00', '2026-12-31 23:59:59');

-- 2.7 Order
INSERT INTO "Order" (order_Id, memberid, groupid, voucherId, totalAmount, orderDate, status) VALUES
('o260100001', 'm260100001', 'g260100001', 'v260100002', 300, '2026-05-25 14:20:00', '2'),
('o260100002', 'm260100003', 'g260100002', NULL, 390, '2026-05-26 16:45:00', '2'),
('o260100003', 'm260100005', 'g260100003', 'v260100003', 250, '2026-05-28 11:30:00', '2'),
('o260100004', 'm260100001', 'g260100004', NULL, 990, '2025-12-10 15:00:00', '2'), -- 歷史過期隔離測試數據
('o260100005', 'm260100007', 'g260100005', 'v260100004', 850, '2026-06-03 09:15:00', '1'),
('o260100006', 'm260100008', 'g260100006', 'v260100005', 360, '2026-06-06 18:22:00', '1'),
('o260100007', 'm260100009', 'g260100007', 'v260100006', 320, '2026-06-11 10:05:00', '1'),
('o260100008', 'm260100010', 'g260100008', 'v260100007', 450, '2026-06-13 13:40:00', '1'),
('o260100009', 'm260100003', 'g260100009', 'v260100008', 590, '2026-06-15 15:55:00', '1'),
('o260100010', 'm260100005', 'g260100010', 'v260100009', 480, '2026-06-17 21:10:00', '1');

-- 2.8 ProductSpecification
INSERT INTO ProductSpecification (spec_id, orderid, productid, group_name, option_code, option_name) VALUES
('s260100001', 'o260100001', 'pro2600001', '口味', 'C01', '焦糖起司雙拼'),
('s260100002', 'o260100002', 'pro2600002', '尺寸/顏色', 'XL-BLK', '黑色 XL 碼'),
('s260100003', 'o260100003', 'pro2600003', '包裝', 'BOX-01', '精裝禮盒版 12入'),
('s260100004', 'o260100004', 'pro2600004', '規格', 'POT-28', '經典霧黑 28cm'),
('s260100005', 'o260100005', 'pro2600005', '顏色', 'BG-NAVY', '海軍藍'),
('s260100006', 'o260100006', 'pro2600006', '風味', 'CHOC', '濃黑黑巧克力風味'),
('s260100007', 'o260100007', 'pro2600007', '烘焙度', 'LIGHT', '淺烘焙 柑橘花香'),
('s260100008', 'o260100008', 'pro2600008', '顏色', 'UM-GRN', '極光綠'),
('s260100009', 'o260100009', 'pro2600009', '尺寸', 'M-GRY', '涼感太空灰 M碼'),
('s260100010', 'o260100010', 'pro2600010', '類型', 'MIXED', '全無鹽綜合原味堅果');

-- 2.9 Payment
INSERT INTO Payment (payment_id, orderid, paymentMethod, paymentDate, amountPaid, transactionid) VALUES
('t26010100001', 'o260100001', '0', '2026-05-25 14:22:15', 300, 'ECPAY20260525000001'),
('t26010200002', 'o260100002', '1', '2026-05-26 16:46:02', 390, 'LINEPAY20260526998811'),
('t26010300003', 'o260100003', '2', '2026-05-28 11:45:00', 250, 'ATM20260528112233'),
('t26010100004', 'o260100004', '0', '2025-12-10 15:02:00', 990, 'ECPAY20251210000999'), -- 歷史過期金流
('t26010100005', 'o260100005', '0', '2026-06-03 09:17:45', 850, 'ECPAY20260603000524'),
('t26010200006', 'o260100006', '1', '2026-06-06 18:23:10', 360, 'LINEPAY20260606112244'),
('t26010100007', 'o260100007', '0', '2026-06-11 10:06:55', 320, 'ECPAY20260611000123'),
('t26010300008', 'o260100008', '2', '2026-06-13 14:00:00', 450, 'ATM20260613887766'),
('t26010200009', 'o260100009', '1', '2026-06-15 15:56:30', 590, 'LINEPAY20260615554433'),
('t26010100010', 'o260100010', '0', '2026-06-17 21:12:12', 480, 'ECPAY20260617000888');


-- =========================================================================
-- 3. 一般會員分段運轉檢視表 (Member Lifecycle Views)
-- =========================================================================

-- 3.1 階段一：社群導流與規格挑選檢視表
CREATE VIEW View_Member_Browsing_Specs AS
SELECT 
    m.member_id AS buyer_member_id,
    act.username AS buyer_username,
    post.postid_id AS source_post_id,
    g.group_id AS joined_group_id,
    g.groupName AS group_buy_title,
    prod.product_id AS product_id,
    prod.productName AS selected_product,
    ps.group_name AS spec_category,
    ps.option_name AS spec_detail_name
FROM Account act
JOIN Member m ON act.account_Id = m.accountid
JOIN "Order" o ON m.member_id = o.memberid
JOIN GroupBuyGroup g ON o.groupid = g.group_id
JOIN DiscussionPost post ON g.group_id = post.groupid
JOIN ProductSpecification ps ON o.order_Id = ps.orderid
JOIN Product prod ON ps.productid = prod.product_id
WHERE g.deadlineDate >= CURRENT_DATE - INTERVAL '35 days'
  AND o.status != '0';

-- 3.2 階段二：訂單成立與優惠折抵檢視表
CREATE VIEW View_Member_Order_Summary AS
SELECT 
    o.memberid AS buyer_member_id,
    o.order_Id AS order_id,
    o.totalAmount AS original_amount,
    o.orderDate AS checkout_time,
    o.status AS order_status,
    v.voucherCode AS applied_coupon,
    v.validUntil AS coupon_expiry
FROM "Order" o
LEFT JOIN Voucher v ON o.voucherId = v.voucher_id
WHERE o.orderDate >= CURRENT_DATE - INTERVAL '35 days'
  AND o.status != '0';

-- 3.3 階段三：金流支付與安全收據檢視表
CREATE VIEW View_Member_Payment_Receipt AS
SELECT 
    o.memberid AS buyer_member_id,
    o.order_Id AS order_id,
    pm.payment_id AS payment_serial_no,
    pm.amountPaid AS actual_paid,
    pm.paymentMethod AS pay_method,
    pm.paymentDate AS pay_time,
    pm.transactionid AS bank_trace_id
FROM "Order" o
JOIN Payment pm ON o.order_Id = pm.orderid
WHERE o.orderDate >= CURRENT_DATE - INTERVAL '35 days'
  AND o.status != '0';


-- =========================================================================
-- 4. 團主上架與開團分段運轉檢視表 (Leader Lifecycle Views)
-- =========================================================================

-- 4.1 階段一：商品庫存主檔檢視表
CREATE VIEW View_Leader_Product_Inventory AS
SELECT DISTINCT
    g.creatorId AS leader_member_id,
    prod.product_id,
    prod.productName,
    prod.basePrice,
    prod.stockAvailable
FROM Product prod
JOIN ProductSpecification ps ON prod.product_id = ps.productid
JOIN "Order" o ON ps.orderid = o.order_Id
JOIN GroupBuyGroup g ON o.groupid = g.group_id;

-- 4.2 階段二：開團活動成效檢視表
CREATE VIEW View_Leader_Active_Campaigns AS
SELECT 
    g.creatorId AS leader_member_id,
    g.group_id AS campaign_id,
    g.groupName AS campaign_title,
    g.creationDate,
    g.deadlineDate,
    g.state AS campaign_state
FROM GroupBuyGroup g
WHERE g.creationDate >= CURRENT_DATE - INTERVAL '35 days'
  AND g.state != '0';

-- 4.3 階段三：社群宣傳貼文導流檢視表
CREATE VIEW View_Leader_Marketing_Posts AS
SELECT 
    post.memberId AS leader_member_id,
    post.postid_id AS post_id,
    post.postDate,
    post.text_content AS post_content,
    g.group_id AS linked_campaign_id,
    g.groupName AS linked_campaign_title
FROM DiscussionPost post
JOIN GroupBuyGroup g ON post.groupid = g.group_id
WHERE post.postDate >= CURRENT_DATE - INTERVAL '35 days'
  AND g.state != '0';


-- =========================================================================
-- 5. 權限防禦與物理級安全隔離宣告 (Security Hardening)
-- =========================================================================
REVOKE DELETE ON View_Member_Browsing_Specs FROM PUBLIC;
REVOKE DELETE ON View_Member_Order_Summary FROM PUBLIC;
REVOKE DELETE ON View_Member_Payment_Receipt FROM PUBLIC;
REVOKE DELETE ON View_Leader_Product_Inventory FROM PUBLIC;
REVOKE DELETE ON View_Leader_Active_Campaigns FROM PUBLIC;
REVOKE DELETE ON View_Leader_Marketing_Posts FROM PUBLIC;


-- =========================================================================
-- 團購系統擴充模組 (GroupBuy Extension)
-- 在原始 團購.sql 的基礎上新增：
--   1. GroupProduct 關聯表：讓商品可以歸屬到特定團購活動
--   2. 對應的 10 筆種子資料
--   3. 「瀏覽團購／加入團購」所需的新檢視表
--   4. 一個「建立訂單」用的輔助 function（自動產生流水號、檢查狀態）
-- 請在原本的 團購.sql 執行完成之後，再執行這支檔案。
-- =========================================================================

-- -------------------------------------------------------------------------
-- 1. GroupProduct 關聯表
--    一個團購活動(GroupBuyGroup)可以上架多項商品(Product)，
--    並可針對該團購活動設定「團購價」與「該團限定庫存」。
-- -------------------------------------------------------------------------
CREATE TABLE GroupProduct (
    groupProduct_id CHAR(10) NOT NULL,
    groupId CHAR(10) NOT NULL,
    productId CHAR(10) NOT NULL,
    groupPrice INT NOT NULL,
    groupStock INT NOT NULL DEFAULT 0,
    CONSTRAINT PK_GroupProduct PRIMARY KEY (groupProduct_id),
    CONSTRAINT FK_GroupProduct_Group FOREIGN KEY (groupId) REFERENCES GroupBuyGroup(group_id) ON DELETE CASCADE,
    CONSTRAINT FK_GroupProduct_Product FOREIGN KEY (productId) REFERENCES Product(product_id),
    CONSTRAINT UQ_GroupProduct_Pair UNIQUE (groupId, productId),
    CONSTRAINT chk_groupproduct_id_domain CHECK (
        LENGTH(groupProduct_id) = 10
        AND groupProduct_id ~ '^gp[0-9]{8}$'
    ),
    CONSTRAINT chk_groupproduct_price CHECK (groupPrice >= 0),
    CONSTRAINT chk_groupproduct_stock CHECK (groupStock >= 0)
);

-- -------------------------------------------------------------------------
-- 2. 種子資料：把原本 10 個團 對應到 10 項商品（一團一品，沿用既有命名規則）
--    團購價統一抓 Product.basePrice，團購限定庫存設一個合理值。
-- -------------------------------------------------------------------------
INSERT INTO GroupProduct (groupProduct_id, groupId, productId, groupPrice, groupStock) VALUES
('gp00000001', 'g260100001', 'pro2600001', 150, 200),
('gp00000002', 'g260100002', 'pro2600002', 390, 150),
('gp00000003', 'g260100003', 'pro2600003', 250, 100),
('gp00000004', 'g260100004', 'pro2600004', 990, 30),
('gp00000005', 'g260100005', 'pro2600005', 850, 60),
('gp00000006', 'g260100006', 'pro2600006', 180, 180),
('gp00000007', 'g260100007', 'pro2600007', 320, 80),
('gp00000008', 'g260100008', 'pro2600008', 450, 120),
('gp00000009', 'g260100009', 'pro2600009', 590, 90),
('gp00000010', 'g260100010', 'pro2600010', 480, 150);

-- -------------------------------------------------------------------------
-- 3. 會員端「瀏覽團購」檢視表（不限定自己是否已下單，顯示所有進行中的團）
-- -------------------------------------------------------------------------
CREATE VIEW View_Active_GroupBuy_List AS
SELECT
    g.group_id,
    g.groupName AS group_title,
    g.description,
    g.creationDate,
    g.deadlineDate,
    g.state AS group_state,
    leader_acc.username AS leader_username,
    gp.groupProduct_id,
    gp.productId AS product_id,
    prod.productName AS product_name,
    gp.groupPrice AS group_price,
    prod.basePrice AS original_price,
    gp.groupStock AS stock_available,
    prod.minPurchaseQty AS min_purchase_qty
FROM GroupBuyGroup g
JOIN Member leader_m ON g.creatorId = leader_m.member_id
JOIN Account leader_acc ON leader_m.accountid = leader_acc.account_Id
LEFT JOIN GroupProduct gp ON g.group_id = gp.groupId
LEFT JOIN Product prod ON gp.productId = prod.product_id
WHERE g.state = '1'
  AND g.deadlineDate >= CURRENT_TIMESTAMP;

-- -------------------------------------------------------------------------
-- 4. 會員端「指定團購的商品規格選單」輔助檢視表
--    （用來在「加入團購」表單中，列出該團商品 + 歷史上出現過的規格選項，
--      方便會員下單時挑選規格；新規格也可由前端自由輸入）
-- -------------------------------------------------------------------------
CREATE VIEW View_GroupProduct_Spec_Options AS
SELECT DISTINCT
    gp.groupId AS group_id,
    gp.productId AS product_id,
    ps.group_name AS spec_category,
    ps.option_code,
    ps.option_name
FROM GroupProduct gp
JOIN ProductSpecification ps ON gp.productId = ps.productid;

-- -------------------------------------------------------------------------
-- 5. 團主端「我開的團 + 上架商品總覽」檢視表（取代舊的 View_Leader_Product_Inventory
--    舊版只能看到「曾經被下單過」的商品，新版能看到「已上架但尚未被下單」的商品）
-- -------------------------------------------------------------------------
CREATE VIEW View_Leader_GroupProduct_Inventory AS
SELECT
    g.creatorId AS leader_member_id,
    g.group_id,
    g.groupName AS group_title,
    g.state AS group_state,
    gp.groupProduct_id AS group_product_id,
    prod.product_id,
    prod.productName AS product_name,
    gp.groupPrice AS group_price,
    prod.basePrice AS original_price,
    gp.groupStock AS group_stock,
    prod.stockAvailable AS total_stock_on_hand
FROM GroupBuyGroup g
JOIN GroupProduct gp ON g.group_id = gp.groupId
JOIN Product prod ON gp.productId = prod.product_id;

-- -------------------------------------------------------------------------
-- 6. 團主端「該團目前已成立訂單統計」檢視表（看開團成效用，含已加入人數/總額）
-- -------------------------------------------------------------------------
CREATE VIEW View_Leader_Campaign_Orders AS
SELECT
    g.creatorId AS leader_member_id,
    g.group_id,
    g.groupName AS group_title,
    o.order_Id AS order_id,
    o.memberid AS buyer_member_id,
    buyer_acc.username AS buyer_username,
    o.totalAmount AS total_amount,
    o.orderDate AS order_date,
    o.status AS order_status
FROM GroupBuyGroup g
JOIN "Order" o ON g.group_id = o.groupid
JOIN Member buyer_m ON o.memberid = buyer_m.member_id
JOIN Account buyer_acc ON buyer_m.accountid = buyer_acc.account_Id
WHERE o.status != '0';

-- -------------------------------------------------------------------------
-- 7. 權限防禦：延續原檔案的安全隔離宣告
-- -------------------------------------------------------------------------
REVOKE DELETE ON View_Active_GroupBuy_List FROM PUBLIC;
REVOKE DELETE ON View_GroupProduct_Spec_Options FROM PUBLIC;
REVOKE DELETE ON View_Leader_GroupProduct_Inventory FROM PUBLIC;
REVOKE DELETE ON View_Leader_Campaign_Orders FROM PUBLIC;