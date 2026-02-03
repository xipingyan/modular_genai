#include "my_utils.hpp"


bool save_image_bmp(const std::string& filename, const ov::Tensor& image, bool convert_rgb2bgr) {
    try {
        ov::Shape shape = image.get_shape();

        size_t height, width, channels;
        const uint8_t* data = image.data<const uint8_t>();

        if (shape.size() == 4) {
            if (shape[3] == 3) {
                height = shape[1];
                width = shape[2];
                channels = shape[3];
            } else if (shape[1] == 3) {
                std::cerr << "[ERROR] NCHW format not supported for BMP save" << std::endl;
                return false;
            } else {
                std::cerr << "[ERROR] Unknown 4D tensor format" << std::endl;
                return false;
            }
        } else if (shape.size() == 3) {
            height = shape[0];
            width = shape[1];
            channels = shape[2];
        } else {
            std::cerr << "[ERROR] Unsupported tensor shape for image save" << std::endl;
            return false;
        }

        if (channels != 3) {
            std::cerr << "[ERROR] Expected 3 channels, got " << channels << std::endl;
            return false;
        }

        unsigned char file_header[14] = {
            'B', 'M', 0, 0, 0, 0, 0, 0, 0, 0, 54, 0, 0, 0
        };

        unsigned char info_header[40] = {
            40, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 24, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0
        };

        int row_padding = (4 - (width * 3) % 4) % 4;
        int data_size = static_cast<int>((width * 3 + row_padding) * height);
        int file_size = 54 + data_size;

        file_header[2] = file_size & 0xFF;
        file_header[3] = (file_size >> 8) & 0xFF;
        file_header[4] = (file_size >> 16) & 0xFF;
        file_header[5] = (file_size >> 24) & 0xFF;

        info_header[4] = width & 0xFF;
        info_header[5] = (width >> 8) & 0xFF;
        info_header[6] = (width >> 16) & 0xFF;
        info_header[7] = (width >> 24) & 0xFF;

        int32_t neg_height = -static_cast<int32_t>(height);
        info_header[8] = neg_height & 0xFF;
        info_header[9] = (neg_height >> 8) & 0xFF;
        info_header[10] = (neg_height >> 16) & 0xFF;
        info_header[11] = (neg_height >> 24) & 0xFF;

        info_header[20] = data_size & 0xFF;
        info_header[21] = (data_size >> 8) & 0xFF;
        info_header[22] = (data_size >> 16) & 0xFF;
        info_header[23] = (data_size >> 24) & 0xFF;

        std::ofstream file(filename, std::ios::binary);
        if (!file.is_open()) {
            std::cerr << "[ERROR] Failed to open file: " << filename << std::endl;
            return false;
        }

        file.write(reinterpret_cast<char*>(file_header), 14);
        file.write(reinterpret_cast<char*>(info_header), 40);

        unsigned char padding[3] = {0, 0, 0};

        for (size_t y = 0; y < height; ++y) {
            for (size_t x = 0; x < width; ++x) {
                size_t idx = (y * width + x) * 3;
                if (convert_rgb2bgr) {
                    file.put(static_cast<char>(data[idx + 2]));
                    file.put(static_cast<char>(data[idx + 1]));
                    file.put(static_cast<char>(data[idx]));
                } else {
                    file.write(reinterpret_cast<const char*>(data + idx), 3);
                }
            }
            file.write(reinterpret_cast<char*>(padding), row_padding);
        }

        file.close();
        return true;

    } catch (const std::exception& e) {
        std::cerr << "[ERROR] Failed to save image: " << e.what() << std::endl;
        return false;
    }
}