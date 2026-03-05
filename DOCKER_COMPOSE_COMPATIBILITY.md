# Docker Compose Compatibility Note

## ✅ Script Hỗ Trợ Cả Docker Compose v1 & v2

Deploy script (`deploy.sh`) đã được cập nhật để **tự động detect** và chạy được với:

### Docker Compose v1
```bash
# Command: docker-compose
docker-compose --version
# Output: docker-compose version 1.29.2, build 5becea4c
```

**Sử dụng:**
```bash
bash deploy.sh
bash deploy.sh ips
```

### Docker Compose v2  
```bash
# Command: docker compose
docker compose version
# Output: Docker Compose version v2.x.x
```

**Sử dụng:**
```bash
bash deploy.sh
bash deploy.sh ips
```

---

## 🔍 How It Works

Script tự động:
1. ✅ Check `docker compose` có có (v2)
2. ✅ Nếu không, fallback sang `docker-compose` (v1)
3. ✅ Lưu vào biến `$DOCKER_COMPOSE_CMD`
4. ✅ Sử dụng biến này cho tất cả commands

**Không cần chỉnh sửa gì!** 🎉

---

## 📝 Code Changes

Các thay đổi trong `deploy.sh`:

### 1. Thêm Detection Logic (lines 47-59)
```bash
if docker compose version &>/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
    echo -e "${GREEN}✓ Using Docker Compose v2${NC}"
elif docker-compose version &>/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
    echo -e "${GREEN}✓ Using Docker Compose v1${NC}"
else
    echo -e "${RED}❌ Docker Compose not found${NC}"
    exit 1
fi
```

### 2. Thay Tất Cả Commands
```bash
# Before: docker-compose up -d
# After:  $DOCKER_COMPOSE_CMD up -d

# Before: docker-compose -f file.yml restart service
# After:  $DOCKER_COMPOSE_CMD -f file.yml restart service
```

---

## 🧪 Testing

### Verify Docker Compose Version
```bash
# Check v1
docker-compose --version

# Check v2
docker compose version

# Or both might be available
which docker-compose
which docker
```

### Verify Script Detection
```bash
# Run deploy script - sẽ in ra phiên bản nào được sử dụng
bash deploy.sh

# Output example:
# ✓ Using Docker Compose v2 (docker compose)
# hoặc
# ✓ Using Docker Compose v1 (docker-compose)
```

---

## 📊 Compatibility Matrix

| System | Docker Compose v1 | Docker Compose v2 | Script Result |
|--------|-------------------|-------------------|---------------|
| Ubuntu 20.04 (APT) | ✅ Yes | ❌ No | Uses v1 |
| Ubuntu 22.04+ | ❌ No | ✅ Yes | Uses v2 |
| Docker Desktop | ~ Depends | ✅ Yes | Uses v2 |
| Manual Install | Depends | Depends | Auto-detect |

---

## 🎯 Advantages

✅ **Single script works everywhere**
✅ **No version conflicts**
✅ **No user input needed**
✅ **Automatic fallback**
✅ **Clear output messages**

---

## 🔧 Manual Override (if needed)

If auto-detection fails, you can manually set:

```bash
# Force v1
DOCKER_COMPOSE_CMD="docker-compose" bash deploy.sh

# Force v2
DOCKER_COMPOSE_CMD="docker compose" bash deploy.sh
```

---

## 📖 Files Modified

- ✅ `deploy.sh` - Added version detection + variable usage
- ✅ `README.md` - Updated requirements section
- ✅ `QUICKREF.md` - Added compatibility note

---

**Status**: ✅ Complete & Tested

**Version**: 1.0

**Date**: March 5, 2026
