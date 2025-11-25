-- motorx/node_modules/std-env

-- Name: DATABASE_URL
-- Value: postgresql://user:password@localhost:5432/mydb 
-- Value: postgresql://user:password@localhost/mydb 

CREATE TABLE IF NOT EXISTS auth (
	id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
	, email varchar(500) NOT NULL UNIQUE
	, password varchar(2048) NOT NULL);

CREATE TABLE IF NOT EXISTS auctions (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
, name varchar(200) NOT NULL
, location varchar(200) NOT NULL
, address varchar(3000) NULL
, postal_code varchar(12) NULL);

CREATE TABLE IF NOT EXISTS destinations (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
, country_name varchar(200) NOT NULL
, country_code varchar(10) NULL
, port_name varchar(200) NULL);
	  
CREATE TABLE IF NOT EXISTS service_charges (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
	,service_id bigint NOT NULL
	,auction_id bigint NOT NULL
	,charge_name varchar(50) NOT NULL
	,base_price float NOT NULL DEFAULT 0
	,price_level varchar(50) NULL
	,auction_specific boolean NOT NULL DEFAULT false
	,markup_fee int NULL
	,financing_fee float NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS services (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
	,name varchar(200) NOT NULL
	,description varchar(500) NULL
	,category varchar(255) NOT NULL
	,is_active boolean NOT NULL DEFAULT true
	,total_cost float NOT NULL DEFAULT 0
	);

CREATE TABLE IF NOT EXISTS shippers_terminals (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
	,name varchar(200) NOT NULL
	,location varchar(200) NOT NULL
	,address varchar(3000) NULL
	,postal_code varchar(12) NULL);

CREATE TABLE IF NOT EXISTS auth_users (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
	,name varchar(200) NOT NULL
	,email varchar(500) NOT NULL
	,role varchar(200) NOT NULL DEFAULT 'client'
	,is_main_client boolean NOT NULL DEFAULT false
	,main_client_id bigint NULL
	,created_at timestamptz NOT NULL DEFAULT CURRENT_TIMESTAMP);

CREATE TABLE IF NOT EXISTS auth_accounts (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
	,user_id bigint NOT NULL
	,provider varchar(200) NOT NULL
	,type varchar(100) NOT NULL
	,provider_acount_id bigint NOT NULL
	,access_token varchar(255)
    ,expires_at timestamptz DEFAULT CURRENT_TIMESTAMP
    ,refresh_token varchar(2048)
    ,id_token bigint
    ,scope varchar(50)
    ,session_state varchar(50)
    ,token_type varchar(50)
	,password varchar(2048) NOT NULL);

CREATE TABLE IF NOT EXISTS vehicles(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
	,vin varchar(50) NOT NULL
	,description varchar(255)
	,purchase_price float NOT NULL DEFAULT 0.00
	,purchase_date timestamptz DEFAULT CURRENT_TIMESTAMP
	,current_status varchar(50)
	,created_at timestamptz DEFAULT CURRENT_TIMESTAMP
	,client_id bigint NOT NULL
	,auction_id bigint NOT NULL);

CREATE TABLE IF NOT EXISTS client_hierarchy(id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
	,main_client_id bigint NOT NULL
	,sub_client_id bigint NOT NULL);

CREATE TABLE IF NOT EXISTS vehicle_service_details (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
	, vehicle_id bigint NOT NULL
	, service_id bigint NOT NULL
	, status varchar(50));
	
CREATE TABLE IF NOT EXISTS vehicle_service_charges (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
	, service_charge_id bigint
	, vehicle_service_detail_id bigint);
	
CREATE TABLE IF NOT EXISTS auth_verification_token (id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY
	,identifier varchar(255)
	,expires timestamptz
	,token varchar(255));
