# Dataset cập nhật Hoàng Sa và Trường Sa

Các file đã tạo:

- `tourism_destinations_with_archipelagos.json`: thêm 2 địa điểm/lãnh thổ biển đảo:
  - Quần đảo Hoàng Sa — Thành phố Đà Nẵng
  - Quần đảo Trường Sa — Tỉnh Khánh Hòa
- `provinces_with_archipelagos.geojson`: thêm 2 đặc khu biển đảo vào layer cấp tỉnh/bản đồ tổng quan.
- `vietnam_complete_with_archipelagos.geojson`: thay 2 polygon khung đơn giản bằng geometry chi tiết từ `communes.geojson`.
- `provinces_with_archipelagos.parquet`: thêm 2 dòng đặc khu vào bảng cấp tỉnh/layer tổng quan.
- `all_with_archipelagos.parquet`: thêm 2 dòng đặc khu ở cấp layer tổng quan, ngoài 2 dòng cấp xã/đặc khu đã có sẵn trong dữ liệu gốc.
- `communes_with_archipelagos.geojson` và `communes_with_archipelagos.parquet`: bản sao tiện dùng, vì dữ liệu gốc đã có Đặc khu Hoàng Sa và Đặc khu Trường Sa ở cấp xã/đặc khu.

Ghi chú:

- Hoàng Sa được giữ `parent_ten = Thành phố Đà Nẵng`.
- Trường Sa được giữ `parent_ten = Tỉnh Khánh Hòa`.
- Không xóa hoặc sửa dữ liệu gốc; toàn bộ file cập nhật nằm trong thư mục này.
