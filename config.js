// ===== 接続先の設定 =====
// Supabase の「Project Settings → API」に表示される値です。
// SUPABASE_ANON_KEY は「公開してよいキー」（anon key）です。ページに書いても安全なように、
// データベース側の決まり（supabase/schema.sql の RLS）で、他人のデータを読めないようにしています。
// ※「service_role」や「secret」と書かれたキーは絶対にここに書かないでください。
const SUPABASE_URL = "https://peowvqxcceynknomreas.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBlb3d2cXhjY2V5bmtub21yZWFzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTMyMjU5MTYsImV4cCI6MjEwODgwMTkxNn0.Bpo32eGySuA3uX5U1BgZypUYd3gc7sB-L5zuX8ZZZFQ";
