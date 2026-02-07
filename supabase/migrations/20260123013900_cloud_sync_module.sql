-- Location: supabase/migrations/20260123013900_cloud_sync_module.sql
-- Schema Analysis: Fresh project - no existing tables
-- Integration Type: New Module - Cloud Sync for Favorites & Settings
-- Dependencies: None (fresh project)

-- 1. Types for Settings
CREATE TYPE public.theme_mode AS ENUM ('light', 'dark', 'system');
CREATE TYPE public.ai_provider AS ENUM ('openai', 'gemini');

-- 2. Core Tables
-- User Favorites Table (stores favorited quotes)
CREATE TABLE public.user_favorites (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL,
    quote_id INT NOT NULL,
    quote_text TEXT NOT NULL,
    quote_author TEXT,
    quote_category TEXT,
    quote_tags TEXT,
    quote_image TEXT,
    added_date TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_favorite BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- User Settings Table (stores app preferences)
CREATE TABLE public.user_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE,
    theme_mode public.theme_mode DEFAULT 'system'::public.theme_mode,
    notifications_enabled BOOLEAN DEFAULT true,
    daily_notification_time TIME DEFAULT '09:00:00',
    ai_enabled BOOLEAN DEFAULT true,
    ai_provider public.ai_provider DEFAULT 'openai'::public.ai_provider,
    haptic_feedback BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- 3. Essential Indexes
CREATE INDEX idx_user_favorites_user_id ON public.user_favorites(user_id);
CREATE INDEX idx_user_favorites_quote_id ON public.user_favorites(user_id, quote_id);
CREATE INDEX idx_user_favorites_added_date ON public.user_favorites(user_id, added_date DESC);
CREATE INDEX idx_user_settings_user_id ON public.user_settings(user_id);

-- 4. Updated At Trigger Function
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $func$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$func$;

-- 5. Triggers
CREATE TRIGGER update_user_favorites_updated_at
    BEFORE UPDATE ON public.user_favorites
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

CREATE TRIGGER update_user_settings_updated_at
    BEFORE UPDATE ON public.user_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_updated_at_column();

-- 6. Enable RLS
ALTER TABLE public.user_favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_settings ENABLE ROW LEVEL SECURITY;

-- 7. RLS Policies - Simple User Ownership Pattern
CREATE POLICY "users_manage_own_favorites"
ON public.user_favorites
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

CREATE POLICY "users_manage_own_settings"
ON public.user_settings
FOR ALL
TO authenticated
USING (user_id = auth.uid())
WITH CHECK (user_id = auth.uid());

-- 8. Anonymous Access Policies (for preview mode before auth)
CREATE POLICY "anonymous_read_favorites"
ON public.user_favorites
FOR SELECT
TO anon
USING (true);

CREATE POLICY "anonymous_read_settings"
ON public.user_settings
FOR SELECT
TO anon
USING (true);