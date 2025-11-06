-- Create temp_otps table for OTP verification
CREATE TABLE IF NOT EXISTS public.temp_otps (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contact TEXT NOT NULL,
  otp_code TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  verified BOOLEAN DEFAULT false
);

-- Add trigger to auto-delete expired OTPs
CREATE OR REPLACE FUNCTION delete_expired_otps()
RETURNS TRIGGER AS $$
BEGIN
  DELETE FROM public.temp_otps
  WHERE created_at < now() - interval '5 minutes';
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cleanup_expired_otps
  BEFORE INSERT ON public.temp_otps
  FOR EACH ROW
  EXECUTE FUNCTION delete_expired_otps();

-- Enable RLS
ALTER TABLE public.temp_otps ENABLE ROW LEVEL SECURITY;

-- Allow anyone to insert OTPs
CREATE POLICY "Anyone can insert OTPs"
  ON public.temp_otps
  FOR INSERT
  WITH CHECK (true);

-- Allow users to read their own OTPs
CREATE POLICY "Users can read their own OTPs"
  ON public.temp_otps
  FOR SELECT
  USING (true);

-- Allow users to update their own OTPs
CREATE POLICY "Users can update their own OTPs"
  ON public.temp_otps
  FOR UPDATE
  USING (true);

-- Create favorites table
CREATE TABLE IF NOT EXISTS public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  item_id UUID NOT NULL,
  item_type TEXT NOT NULL CHECK (item_type IN ('spot', 'restaurant', 'event', 'accommodation')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT now(),
  UNIQUE (user_id, item_id, item_type)
);

-- Enable RLS on favorites
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;

-- Users can view their own favorites
CREATE POLICY "Users can view own favorites"
  ON public.favorites
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can create their own favorites
CREATE POLICY "Users can create own favorites"
  ON public.favorites
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can delete their own favorites
CREATE POLICY "Users can delete own favorites"
  ON public.favorites
  FOR DELETE
  USING (auth.uid() = user_id);

-- Update profiles table to add onboarding_complete
ALTER TABLE public.profiles
ADD COLUMN IF NOT EXISTS onboarding_complete BOOLEAN DEFAULT false;