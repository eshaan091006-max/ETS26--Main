-- 1. Enable pgjwt extension
CREATE EXTENSION IF NOT EXISTS pgjwt;

-- 2. Update Admin Login RPC to return JWT
CREATE OR REPLACE FUNCTION login_admin_rpc(input_username text, input_password text)
RETURNS TABLE (username text, is_volunteer boolean, token text) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    admin_record record;
    jwt_token text;
BEGIN
    SELECT * INTO admin_record 
    FROM public.admins 
    WHERE admins.username = input_username AND admins.password = input_password;

    IF FOUND THEN
        SELECT sign(
            row_to_json(r), current_setting('app.settings.jwt_secret')
        ) INTO jwt_token
        FROM (
            SELECT 
                'authenticated' as role,
                'admin' as user_role,
                input_username as username,
                extract(epoch from now() + interval '7 days') as exp
        ) r;

        RETURN QUERY SELECT admin_record.username, admin_record.is_volunteer, jwt_token;
    END IF;
    RETURN;
END;
$$;

-- 3. Update Contingent Login RPC to return JWT
CREATE OR REPLACE FUNCTION login_contingent_rpc(input_code text, input_password text)
-- If your current contingent RPC returns other fields, add them back here (e.g., college_name, contingent_id)
RETURNS TABLE (contingent_id int, code text, token text) 
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    cont_record record;
    jwt_token text;
BEGIN
    SELECT * INTO cont_record 
    FROM public.contingents 
    WHERE contingents.code = input_code AND contingents.password = input_password;

    IF FOUND THEN
        SELECT sign(
            row_to_json(r), current_setting('app.settings.jwt_secret')
        ) INTO jwt_token
        FROM (
            SELECT 
                'authenticated' as role,
                'contingent' as user_role,
                cont_record.contingent_id as contingent_id,
                extract(epoch from now() + interval '7 days') as exp
        ) r;

        -- Make sure these return columns match the RETURNS TABLE definition above exactly
        RETURN QUERY SELECT cont_record.contingent_id, cont_record.code, jwt_token;
    END IF;
    RETURN;
END;
$$;
