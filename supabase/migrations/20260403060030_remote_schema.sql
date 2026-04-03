SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;


COMMENT ON SCHEMA "public" IS 'standard public schema';



CREATE EXTENSION IF NOT EXISTS "pg_graphql" WITH SCHEMA "graphql";






CREATE EXTENSION IF NOT EXISTS "pg_stat_statements" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA "extensions";






CREATE EXTENSION IF NOT EXISTS "supabase_vault" WITH SCHEMA "vault";






CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA "extensions";






CREATE TYPE "public"."user_role" AS ENUM (
    'admin',
    'trainer',
    'member'
);


ALTER TYPE "public"."user_role" OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."get_my_role"() RETURNS "public"."user_role"
    LANGUAGE "sql" STABLE SECURITY DEFINER
    AS $$
select role from profiles where id = auth.uid();
$$;


ALTER FUNCTION "public"."get_my_role"() OWNER TO "postgres";


CREATE OR REPLACE FUNCTION "public"."handle_new_user"() RETURNS "trigger"
    LANGUAGE "plpgsql" SECURITY DEFINER
    AS $$
begin
insert into public.profiles (id, email, full_name)
values (
new.id,
new.email,
new.raw_user_meta_data->>'full_name'
);
if (new.raw_user_meta_data->>'role' = 'trainer') then
insert into public.trainers (profile_id) values (new.id);
else
insert into public.members (profile_id) values (new.id);
end if;
return new;
end;
$$;


ALTER FUNCTION "public"."handle_new_user"() OWNER TO "postgres";

SET default_tablespace = '';

SET default_table_access_method = "heap";


CREATE TABLE IF NOT EXISTS "public"."bookings" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "class_id" "uuid",
    "member_id" "uuid",
    "booked_at" timestamp with time zone DEFAULT "now"(),
    "status" "text" DEFAULT 'confirmed'::"text"
);


ALTER TABLE "public"."bookings" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."classes" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "trainer_id" "uuid",
    "title" "text" NOT NULL,
    "description" "text",
    "schedule" timestamp with time zone,
    "capacity" integer DEFAULT 20,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."classes" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."members" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid",
    "membership_type" "text",
    "start_date" "date",
    "end_date" "date",
    "is_active" boolean DEFAULT true,
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."members" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."profiles" (
    "id" "uuid" NOT NULL,
    "full_name" "text",
    "email" "text",
    "role" "public"."user_role" DEFAULT 'member'::"public"."user_role",
    "phone" "text",
    "avatar_url" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."profiles" OWNER TO "postgres";


CREATE TABLE IF NOT EXISTS "public"."trainers" (
    "id" "uuid" DEFAULT "gen_random_uuid"() NOT NULL,
    "profile_id" "uuid",
    "specialization" "text",
    "bio" "text",
    "created_at" timestamp with time zone DEFAULT "now"()
);


ALTER TABLE "public"."trainers" OWNER TO "postgres";


ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_class_id_member_id_key" UNIQUE ("class_id", "member_id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."classes"
    ADD CONSTRAINT "classes_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."members"
    ADD CONSTRAINT "members_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."trainers"
    ADD CONSTRAINT "trainers_pkey" PRIMARY KEY ("id");



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_class_id_fkey" FOREIGN KEY ("class_id") REFERENCES "public"."classes"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."bookings"
    ADD CONSTRAINT "bookings_member_id_fkey" FOREIGN KEY ("member_id") REFERENCES "public"."members"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."classes"
    ADD CONSTRAINT "classes_trainer_id_fkey" FOREIGN KEY ("trainer_id") REFERENCES "public"."trainers"("id");



ALTER TABLE ONLY "public"."members"
    ADD CONSTRAINT "members_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."profiles"
    ADD CONSTRAINT "profiles_id_fkey" FOREIGN KEY ("id") REFERENCES "auth"."users"("id") ON DELETE CASCADE;



ALTER TABLE ONLY "public"."trainers"
    ADD CONSTRAINT "trainers_profile_id_fkey" FOREIGN KEY ("profile_id") REFERENCES "public"."profiles"("id") ON DELETE CASCADE;



ALTER TABLE "public"."bookings" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "bookings: admin all" ON "public"."bookings" USING (("public"."get_my_role"() = 'admin'::"public"."user_role"));



CREATE POLICY "bookings: member delete own" ON "public"."bookings" FOR DELETE USING (("member_id" IN ( SELECT "members"."id"
   FROM "public"."members"
  WHERE ("members"."profile_id" = "auth"."uid"()))));



CREATE POLICY "bookings: member insert" ON "public"."bookings" FOR INSERT WITH CHECK (("member_id" IN ( SELECT "members"."id"
   FROM "public"."members"
  WHERE ("members"."profile_id" = "auth"."uid"()))));



CREATE POLICY "bookings: member read own" ON "public"."bookings" FOR SELECT USING (("member_id" IN ( SELECT "members"."id"
   FROM "public"."members"
  WHERE ("members"."profile_id" = "auth"."uid"()))));



CREATE POLICY "bookings: member update own" ON "public"."bookings" FOR UPDATE USING (("member_id" IN ( SELECT "members"."id"
   FROM "public"."members"
  WHERE ("members"."profile_id" = "auth"."uid"()))));



ALTER TABLE "public"."classes" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "classes: admin all" ON "public"."classes" USING (("public"."get_my_role"() = 'admin'::"public"."user_role"));



CREATE POLICY "classes: public read" ON "public"."classes" FOR SELECT USING (true);



CREATE POLICY "classes: trainer delete own" ON "public"."classes" FOR DELETE USING (("trainer_id" IN ( SELECT "trainers"."id"
   FROM "public"."trainers"
  WHERE ("trainers"."profile_id" = "auth"."uid"()))));



CREATE POLICY "classes: trainer insert" ON "public"."classes" FOR INSERT WITH CHECK (("trainer_id" IN ( SELECT "trainers"."id"
   FROM "public"."trainers"
  WHERE ("trainers"."profile_id" = "auth"."uid"()))));



CREATE POLICY "classes: trainer update own" ON "public"."classes" FOR UPDATE USING (("trainer_id" IN ( SELECT "trainers"."id"
   FROM "public"."trainers"
  WHERE ("trainers"."profile_id" = "auth"."uid"()))));



ALTER TABLE "public"."members" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "members: admin all" ON "public"."members" USING (("public"."get_my_role"() = 'admin'::"public"."user_role"));



CREATE POLICY "members: self read" ON "public"."members" FOR SELECT USING (("profile_id" = "auth"."uid"()));



ALTER TABLE "public"."profiles" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "profiles: admin all" ON "public"."profiles" USING (("public"."get_my_role"() = 'admin'::"public"."user_role"));



CREATE POLICY "profiles: self read" ON "public"."profiles" FOR SELECT USING (("auth"."uid"() = "id"));



CREATE POLICY "profiles: self update" ON "public"."profiles" FOR UPDATE USING (("auth"."uid"() = "id"));



ALTER TABLE "public"."trainers" ENABLE ROW LEVEL SECURITY;


CREATE POLICY "trainers: admin all" ON "public"."trainers" USING (("public"."get_my_role"() = 'admin'::"public"."user_role"));



CREATE POLICY "trainers: public read" ON "public"."trainers" FOR SELECT USING (true);



CREATE POLICY "trainers: self update" ON "public"."trainers" FOR UPDATE USING (("profile_id" = "auth"."uid"()));





ALTER PUBLICATION "supabase_realtime" OWNER TO "postgres";


GRANT USAGE ON SCHEMA "public" TO "postgres";
GRANT USAGE ON SCHEMA "public" TO "anon";
GRANT USAGE ON SCHEMA "public" TO "authenticated";
GRANT USAGE ON SCHEMA "public" TO "service_role";

























































































































































GRANT ALL ON FUNCTION "public"."get_my_role"() TO "anon";
GRANT ALL ON FUNCTION "public"."get_my_role"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."get_my_role"() TO "service_role";



GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "anon";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "authenticated";
GRANT ALL ON FUNCTION "public"."handle_new_user"() TO "service_role";


















GRANT ALL ON TABLE "public"."bookings" TO "anon";
GRANT ALL ON TABLE "public"."bookings" TO "authenticated";
GRANT ALL ON TABLE "public"."bookings" TO "service_role";



GRANT ALL ON TABLE "public"."classes" TO "anon";
GRANT ALL ON TABLE "public"."classes" TO "authenticated";
GRANT ALL ON TABLE "public"."classes" TO "service_role";



GRANT ALL ON TABLE "public"."members" TO "anon";
GRANT ALL ON TABLE "public"."members" TO "authenticated";
GRANT ALL ON TABLE "public"."members" TO "service_role";



GRANT ALL ON TABLE "public"."profiles" TO "anon";
GRANT ALL ON TABLE "public"."profiles" TO "authenticated";
GRANT ALL ON TABLE "public"."profiles" TO "service_role";



GRANT ALL ON TABLE "public"."trainers" TO "anon";
GRANT ALL ON TABLE "public"."trainers" TO "authenticated";
GRANT ALL ON TABLE "public"."trainers" TO "service_role";









ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON SEQUENCES TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON FUNCTIONS TO "service_role";






ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "postgres";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "anon";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "authenticated";
ALTER DEFAULT PRIVILEGES FOR ROLE "postgres" IN SCHEMA "public" GRANT ALL ON TABLES TO "service_role";































drop extension if exists "pg_net";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
begin
-- Always create a profile row first
insert into public.profiles (id, email, full_name)
values (
new.id,
new.email,
new.raw_user_meta_data->>'full_name'
);
-- Create member or trainer row based on role passed at signup
if (new.raw_user_meta_data->>'role' = 'trainer') then
insert into public.trainers (profile_id) values (new.id);
else
-- Default: everyone gets a member row
insert into public.members (profile_id) values (new.id);
end if;
return new;
end;
$function$
;

CREATE TRIGGER on_auth_user_created AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();


