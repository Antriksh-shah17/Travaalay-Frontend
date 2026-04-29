# Image Loading - Quick Test Guide

## 🚀 Quick Start

### 1. **Restart Backend** (includes image URLs in Gemini prompt)
```bash
cd Travaalay_Backend_Node
npm run dev
```

### 2. **Run Flutter App**
```bash
cd traavaalay
flutter run -v
```

### 3. **Generate Itinerary** in app
- Enter city: "Mumbai"
- Enter days: "2"
- Click "Generate Itinerary"

### 4. **Check Console for Image Logs**
```
🖼️ Loading image: https://images.unsplash.com/... (isUrl: true)
✅ Image loaded successfully
📊 Images: 5 with URLs, 0 without
```

---

## 📊 What to Look For

### ✅ Success Indicators
```
✅ Image loaded successfully
📊 Images: 5 with URLs, 0 without
(All images showing = SUCCESS)
```

### ⚠️ Warning Signs
```
❌ Image failed to load
📊 Images: 0 with URLs, 5 without
(Shows placeholders = API not returning image_url)
```

---

## 🔍 If Images Still Not Showing

### Step 1: Check Backend Response
```bash
curl -X POST https://wnn3xmpd-5000.inc1.devtunnels.ms/api/travai \
  -H 'Content-Type: application/json' \
  -d '{"city":"Mumbai","days":2}' | jq '.itinerary.days[0].places[0]'
```

Look for:
```json
{
  "name": "Gateway of India",
  "description": "...",
  "image_url": "https://images.unsplash.com/..."
}
```

**If image_url is missing:**
- Backend is using old prompt
- Restart: `npm run dev`

**If image_url is there but images not showing:**
- Check Flutter console for errors
- Check internet connection
- Try refreshing in Flutter

### Step 2: Check Flutter Console
```
Look for any of these:
❌ Image failed to load: <error message>
Network is unreachable = Internet issue
SocketException = Connection problem
SSLException = HTTPS certificate issue
```

### Step 3: Check API Response in Chrome DevTools
1. Open Chrome
2. Go to `chrome://inspect`
3. Select your device
4. Open DevTools Network tab
5. Filter by "image" or "unsplash"
6. Check if image requests are being made

---

## 🛠️ Common Issues

### Issue: "Image unavailable" message in place cards
**Cause:** Image URL from API is broken
**Fix:** 
1. Check backend logs
2. Verify Gemini is returning valid URLs
3. Restart backend

### Issue: All placeholders (colored boxes with icons)
**Cause:** No URLs from backend OR network blocked
**Fix:**
1. Verify response has `image_url`
2. Check internet connection
3. Check if unsplash.com is accessible

### Issue: Spinning loader never stops
**Cause:** Image URL blocked or very slow network
**Fix:**
1. Wait longer (might be slow)
2. Check if unsplash.com is accessible
3. Check firewall settings

### Issue: Generic travel image instead of location-specific
**Cause:** API URL returned is generic or fallback triggered
**Fix:**
1. Check Gemini is generating specific URLs
2. Verify backend prompt was updated
3. Restart backend: `npm run dev`

---

## 📋 Verification Checklist

- [ ] Backend running on HTTPS URL
- [ ] Backend shows "Server running" message
- [ ] Flutter shows no connection errors
- [ ] Generated itinerary loads
- [ ] Console shows ✅ Image logs
- [ ] Places show images (not placeholders)
- [ ] Food items show images
- [ ] All 5-7 images load

---

## 🔧 Reset/Restart

If images still not showing after testing:

### Full Reset
```bash
# Terminal 1: Stop servers
# Terminal 2: Stop Flutter app

# Clean backend
cd Travaalay_Backend_Node
rm -rf node_modules package-lock.json
npm install
npm run dev

# Clean Flutter
cd traavaalay
flutter clean
flutter pub get
flutter run -v

# Check logs
tail -f logs/combined/combined-$(date +%Y-%m-%d).log | grep image
```

### Verify Changes
```bash
# Check travaiRoutes.js has image_url in prompt
grep "image_url" Travaalay_Backend_Node/routes/travaiRoutes.js

# Check ItineraryPage.dart uses image_url
grep "image_url" traavaalay/lib/View/User/ItineraryPage.dart

# Should show: YES for both
```

---

## 📊 Expected Response

### Good Response (Has Images)
```json
{
  "itinerary": {
    "days": [
      {
        "day": 1,
        "places": [
          {
            "name": "Gateway of India",
            "description": "Iconic monument...",
            "image_url": "https://images.unsplash.com/photo-1507525..."
          }
        ],
        "food": [
          {
            "name": "Vada Pav",
            "cuisine": "Maharashtrian",
            "description": "Street food...",
            "image_url": "https://images.unsplash.com/photo-1476..."
          }
        ],
        "tips": "Visit in morning"
      }
    ]
  }
}
```

### Bad Response (No Images)
```json
{
  "itinerary": {
    "days": [
      {
        "day": 1,
        "places": [
          {
            "name": "Gateway of India",
            "description": "Iconic monument..."
            // ❌ Missing: "image_url"
          }
        ]
      }
    ]
  }
}
```

---

## 💡 Tips

1. **Clear DevTools Cache:** DevTools → Storage → Clear Site Data
2. **Force Refresh:** `flutter run --no-fast-start`
3. **Check Network:** Open DevTools → Network → browse app
4. **Monitor Logs:** `tail -f logs/combined/combined-$(date +%Y-%m-%d).log`
5. **Test Another City:** Try "Delhi" instead of "Mumbai"

---

## 📞 Support Info

If still having issues, check:
1. **Backend logs:** `logs/error/error-YYYY-MM-DD.log`
2. **Flutter console:** For 🖼️ image logs
3. **Network requests:** DevTools Network tab
4. **API response:** Use curl to test directly
5. **Device internet:** Can you browse images.unsplash.com?

---

**Goal:** Generate itinerary → See images load with ✅ logs → Enjoy the trip! 🎉
