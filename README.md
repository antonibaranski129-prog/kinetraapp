# PLYOTIC

PWA do analizy skoków i RSI z filmów slow motion. Wyniki zapisują się tylko na urządzeniu.

## Wdrożenie
Wgraj całą zawartość do repozytorium GitHub i włącz Pages (Settings → Pages → branch main, root). Na iPhonie: Safari → Udostępnij → Dodaj do ekranu początkowego.

## Logowanie (opcjonalne)
1. Projekt w Supabase, uruchom `supabase-profiles.sql` w SQL Editor.
2. Authentication → Providers: włącz Google i Email (magic link).
3. Authentication → URL Configuration: dodaj adres strony jako Site URL i Redirect URL.
4. Wpisz `SUPABASE_URL` i `SUPABASE_ANON_KEY` w `config.js`.
