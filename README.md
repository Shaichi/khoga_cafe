# Khoga Coffee Shop 

Chào mừng các thành viên đến với dự án **Khoga Coffee Shop**. Đây là kho lưu trữ mã nguồn của dự án, được thiết kế theo chuẩn nguyên khối module hóa (Modular Monolith) dựa trên nguyên tắc **COMET Information Hiding**.

Dưới đây là các hướng dẫn chi tiết để toàn team cài đặt môi trường và tuân thủ quy trình code đồng nhất.

---

## 🛠 1. Công Nghệ Sử Dụng (Tech Stack)

Dự án sử dụng các công nghệ hiện đại nhất:
- **Ngôn ngữ:** Java 21 (LTS)
- **Framework:** Spring Boot (WebMVC, Data JPA, Validation)
- **Cơ sở dữ liệu:** Microsoft SQL Server
- **Công cụ hỗ trợ:** Lombok (giảm boilerplate code), Maven
- **Tài liệu API:** Swagger / OpenAPI 3

---

## 💻 2. Hướng Dẫn Cài Đặt Môi Trường

Để code và chạy được dự án, các thành viên trong team cần cài đặt các phần mềm sau:

### 2.1. Cài đặt Java Development Kit (JDK 21)
Dự án bắt buộc dùng **JDK 21**. Trên Windows, bạn có thể cài nhanh bằng PowerShell (chạy với quyền Admin):
```powershell
winget install Microsoft.OpenJDK.21 --accept-package-agreements --accept-source-agreements
```
*(Nếu dùng IntelliJ IDEA, hãy nhớ vào `File -> Project Structure` để set SDK là JDK 21).*

### 2.2. Cài đặt Cơ sở dữ liệu (MS SQL Server)
1. Cài đặt **SQL Server Developer Edition** và công cụ quản lý **SQL Server Management Studio (SSMS)**.
2. Bật tài khoản `sa` và đặt mật khẩu (Ví dụ: `123`).
3. Mở SSMS, chạy câu lệnh SQL sau để tạo database trống:
   ```sql
   CREATE DATABASE khoga_coffee_shop;
   ```

### 2.3. Cấu hình ứng dụng
Mở file `src/main/resources/application.properties` và đảm bảo thông tin kết nối khớp với máy của bạn:
```properties
spring.datasource.url=jdbc:sqlserver://localhost:1433;databaseName=khoga_coffee_shop;encrypt=true;trustServerCertificate=true;
spring.datasource.username=sa
spring.datasource.password=123
```

---

## 🚀 3. Hướng Dẫn Chạy Dự Án

### Cách 1: Dùng IntelliJ IDEA (Khuyên dùng)
- Mở thư mục gốc của dự án bằng IntelliJ.
- Đợi Maven tải xong các thư viện.
- Tìm file `src/main/java/com/khoga/CoffeeshopApplication.java`, click chuột phải chọn **Run 'CoffeeshopApplication'**.

### Cách 2: Dùng Terminal / PowerShell
```powershell
./mvnw clean spring-boot:run
```

**✅ Kiểm tra thành công:**
- Khi Console hiện dòng `Started CoffeeshopApplication`, mở trình duyệt truy cập Swagger UI để xem toàn bộ tài liệu API tự động:
- 👉 **[http://localhost:8080/swagger-ui.html](http://localhost:8080/swagger-ui.html)**

*(Ngay lần chạy đầu tiên, Hibernate sẽ tự động sinh toàn bộ 22 bảng vào database SQL Server dựa trên các Entity đã được định nghĩa).*

---

## 📐 4. Cấu Trúc Thư Mục (Project Structure)

Dự án có 18 Subsystems (Module). Ví dụ: `com.khoga.auth`, `com.khoga.catalog`, `com.khoga.order`... Mỗi người khi nhận task làm module nào thì chỉ code bên trong thư mục module đó.

Bên cạnh đó, có một thư mục đặc biệt là **`com.khoga.common` (Shared Persistence Layer)** dùng chung cho cả team:
- `model`: Chứa tất cả 22 Entities của Database.
- `repository`: Chứa 21 JPA Repositories.
- `dto`: Chứa các object giao tiếp (như `ApiResponse`).
- `exception`: Chứa bộ bắt lỗi dùng chung.

---

## ⚠️ 5. Quy Trình & Tiêu Chuẩn Code BẮT BUỘC

Để giữ cho Base Framework luôn sạch sẽ và đồng bộ, **toàn team cần tuân thủ 3 quy tắc sống còn sau**:

### Quy tắc 1: API Response chuẩn hóa
Tuyệt đối **KHÔNG** trả về Object thô (ví dụ `return user;`). Mọi API Controller **bắt buộc** phải gói kết quả vào `ApiResponse<T>`.
```java
// ĐÚNG:
return ResponseEntity.ok(ApiResponse.success(user, "Lấy thông tin thành công"));

// NẾU CÓ LỖI (Trực tiếp):
return ResponseEntity.badRequest().body(ApiResponse.error("Sai mật khẩu"));
```

### Quy tắc 2: Không bắt `try-catch` thủ công để trả về lỗi
Dự án đã có `GlobalExceptionHandler`. Nếu code dưới tầng Service gặp lỗi nghiệp vụ, hãy chủ động `throw` ra Custom Exception, hệ thống sẽ tự động hứng và trả về HTTP 400/404 với JSON đúng chuẩn cho Frontend.
```java
// Khi không tìm thấy dữ liệu:
throw new ResourceNotFoundException("Không tìm thấy món nước với ID: " + id);

// Khi lỗi nghiệp vụ (ví dụ: Hết hàng):
throw new AppException("Nguyên liệu không đủ để pha chế!");
```

### Quy tắc 3: Luôn kế thừa `BaseEntity`
Bất cứ khi nào bạn tạo một bảng mới (Entity mới), hãy nhớ kế thừa `extends BaseEntity`.
- **Tuyệt đối KHÔNG** tự viết các trường `createdAt`, `updatedAt` trong Entity.
- `BaseEntity` đã được tích hợp JPA Auditing (`@EntityListeners`), nó sẽ tự động cập nhật thời gian ghi vào Database mà bạn không cần phải làm gì thêm!

---
*Happy Coding! ☕ - Khoga Team*
