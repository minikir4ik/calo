# Calo — Ship to App Store

## Status
- [x] Phase 0: Accounts & Credentials (complete)
- [x] Phase 1: SwiftUI Project Setup (complete — replaced Expo)
- [x] Phase 2: Gemini + USDA Pipeline (complete — on-device, no server)
- [x] Phase 3: RevenueCat In-App Purchases (complete)
- [x] Phase 4: Sentry Error Tracking (complete)
- [x] Phase 5: Design Polish + App Store Assets (complete — design overhaul)
- [ ] Phase 6: TestFlight + App Store Submit

## Credentials
- Apple Team ID: 696L6BMH35
- App Store Apple ID: 6762078940
- Bundle ID: com.minilabs.calo
- Gemini API Key: in Config.xcconfig
- USDA API Key: in Config.xcconfig
- Sentry DSN (mobile): https://cd001bc310b26e1a778634fe5014c1a0@o4511206411534336.ingest.us.sentry.io/4511206417956864
- RevenueCat: account created, products NOT yet configured
- MongoDB Atlas: mongodb+srv://calo_api:ilumm5IWxV8Yms3Y@calo-prod.hind1vh.mongodb.net/calo_prod (legacy — may not need)
- Render: calo-api.onrender.com deployed (legacy — may not need)
- Sandbox tester: created in App Store Connect
- Expo/EAS: minikir4ik (legacy — not used for SwiftUI build)

## Architecture (SwiftUI rewrite)
- Native SwiftUI app — NO backend server
- Gemini 2.5 Flash called directly from device
- USDA FoodData Central called directly from device
- SwiftData for local persistence
- CloudKit sync planned for premium (not wired yet)
- RevenueCat for IAP (not wired yet)
- No Expo, no React Native, no FastAPI, no Render needed

## Phase 3 TODO (next session)
- [ ] App Store Connect: Create subscription group "Calo Premium"
- [ ] App Store Connect: Add product calo_weekly_499 ($4.99/week auto-renewable)
- [ ] App Store Connect: Add product calo_lifetime_2999 ($29.99 non-consumable)
- [ ] App Store Connect: Generate App-Specific Shared Secret
- [ ] RevenueCat: Add Apple App Store app with bundle ID com.minilabs.calo
- [ ] RevenueCat: Paste shared secret
- [ ] RevenueCat: Create entitlement "premium"
- [ ] RevenueCat: Create products, map to premium
- [ ] RevenueCat: Create offering "default" with both packages
- [x] Code: Add RevenueCat SDK via Swift Package Manager
- [x] Code: Initialize Purchases in CaloApp.swift
- [x] Code: Rewrite PaywallView to use real RevenueCat offerings
- [x] Code: Create PremiumManager class to check entitlements
- [x] Code: Wire scan limit enforcement to PremiumManager
- [x] Code: Wire share watermark to PremiumManager
- [x] Code: Add Restore Purchases functionality
- [ ] Test: Sandbox purchase weekly
- [ ] Test: Sandbox purchase lifetime
- [ ] Test: Restore purchases
- [ ] Test: Free user hits 3 scan limit → paywall appears

## Phase 4 TODO
- [x] Add Sentry SDK via SPM
- [x] Initialize in CaloApp.swift
- [ ] Test error capture

## Phase 5 TODO (Design + Assets)
- [x] DESIGN: Scan tab — full screen camera, no placeholder box
- [x] DESIGN: Scan tab — remove title, camera IS the screen
- [x] DESIGN: All cards — darken backgrounds to Color(white: 0.08)
- [x] DESIGN: Paywall buttons — solid coral, not washed pink
- [x] DESIGN: Tab bar — ensure Liquid Glass styling works
- [x] DESIGN: Result screen — polish macro breakdown layout
- [ ] DESIGN: Add app icon (1024x1024 coral flame on dark background)
- [ ] DESIGN: Add launch screen with Calo branding
- [ ] ASSETS: Screenshots for 6.7" display (5-8 total)
- [ ] ASSETS: Privacy Policy hosted URL
- [ ] ASSETS: Terms of Service hosted URL
- [ ] ASSETS: App Store description, keywords, subtitle
- [ ] ASSETS: iOS Privacy Manifest in Info.plist
- [x] FIX: Gemini text-only analysis — text prompt path already correct
- [ ] FIX: Camera integration on real device
- [x] FIX: Date chip highlighting (only today should be coral)

## Phase 6 TODO
- [ ] Archive build in Xcode
- [ ] Upload to App Store Connect
- [ ] TestFlight full test pass
- [ ] Submit for App Store review

## Known Bugs
- Camera placeholder is a gray box on simulator (test on device)
- RevenueCat products not yet configured in dashboard

## Legacy (not needed for SwiftUI build)
- ~/calo — original Expo/React Native app (keep for reference)
- Render deployment at calo-api.onrender.com (can be shut down)
- MongoDB Atlas database (can keep for now, not used by SwiftUI app)
