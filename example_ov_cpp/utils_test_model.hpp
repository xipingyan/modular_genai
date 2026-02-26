#pragma once

#include <string>
#include <vector>
#include <openvino/runtime/core.hpp>

enum class TestModelType
{
    VAE_DECODER,               // < 256M
    QWEN2_5_VL_TEXT_EMB_MODEL, // 638M
    TRANSFORMER                // > 6G
};

class TestModel
{
protected:
    TestModel() = default;

public:
    virtual ~TestModel() = default;
    std::shared_ptr<ov::Model> get_model() const { return _model; }
    const std::string& get_model_path() const { return _model_path; }
    const std::string& get_model_path_bin() const { return _model_path_bin; }

    virtual std::vector<ov::Tensor> get_input() = 0;
    // virtual std::vector<ov::Tensor> get_expected_output() = 0;

    using PTR = std::shared_ptr<TestModel>;
    static PTR create(const TestModelType &model_type, ov::Core &core);

protected:
    std::string _model_path;
    std::string _model_path_bin;

    std::shared_ptr<ov::Model> _model;
};