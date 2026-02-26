#include "utils_test_model.hpp"

class VaeDecoderTestModel : public TestModel
{
public:
    VaeDecoderTestModel(ov::Core &core)
    {
        _model_path = "../openvino.genai/tests/module_genai/cpp/test_models/Z-Image-Turbo-fp16-ov/vae_decoder/openvino_model.xml";
        _model_path_bin = "../openvino.genai/tests/module_genai/cpp/test_models/Z-Image-Turbo-fp16-ov/vae_decoder/openvino_model.bin";

        _model = core.read_model(_model_path);
    }
    std::vector<ov::Tensor> get_input() override
    {
        std::vector<ov::Tensor> inputs;
        // Create a dummy input tensor with the expected shape and type
        ov::Shape input_shape = {1, 16, 64, 64};
        ov::element::Type input_type = ov::element::f32;
        ov::Tensor input_tensor(input_type, input_shape);

        // Fill the input tensor with some data (e.g., random values)
        float *input_data = input_tensor.data<float>();
        for (size_t i = 0; i < input_tensor.get_size(); ++i)
        {
            input_data[i] = static_cast<float>(i) / input_tensor.get_size();
        }
        inputs.push_back(input_tensor);
        return inputs;
    }
};

class TransformerTestModel : public TestModel
{
public:
    TransformerTestModel(ov::Core &core)
    {
        _model_path = "../openvino.genai/tests/module_genai/cpp/test_models/Z-Image-Turbo-fp16-ov/transformer/openvino_model.xml";
        _model_path_bin = "../openvino.genai/tests/module_genai/cpp/test_models/Z-Image-Turbo-fp16-ov/transformer/openvino_model.bin";
        _model = core.read_model(_model_path);
    }
    std::vector<ov::Tensor> get_input() override {
        std::vector<ov::Tensor> inputs;
        // hidden_states[1,16,16,16,16]
        ov::Shape input_shape = {1, 16, 16, 16, 16};
        ov::element::Type input_type = ov::element::f32;
        ov::Tensor input_tensor(input_type, input_shape);
        float *input_data = input_tensor.data<float>();
        for (size_t i = 0; i < input_tensor.get_size(); ++i)
        {
            input_data[i] = static_cast<float>(i) / input_tensor.get_size();
        }
        inputs.push_back(input_tensor);

        // encoder_hidden_states[1,101,2560]
        ov::Shape enc_shape = {1, 101, 2560};
        ov::element::Type enc_type = ov::element::f32;
        ov::Tensor enc_tensor(enc_type, enc_shape);
        float *enc_data = enc_tensor.data<float>();
        for (size_t i = 0; i < enc_tensor.get_size(); ++i)
        {
            enc_data[i] = static_cast<float>(i) / enc_tensor.get_size();
        }
        inputs.push_back(enc_tensor);

        // timestep[1]
        ov::Shape time_shape = {1};
        ov::element::Type time_type = ov::element::f32;
        ov::Tensor time_tensor(time_type, time_shape);
        float *time_data = time_tensor.data<float>();
        for (size_t i = 0; i < time_tensor.get_size(); ++i)
        {
            time_data[i] = static_cast<float>(i) / time_tensor.get_size();
        }
        inputs.push_back(time_tensor);

        return inputs;
    }
};

class QWEN2_5_VL_TEXT_EMB_TestModel : public TestModel
{
public:
    QWEN2_5_VL_TEXT_EMB_TestModel(ov::Core &core)
    {
        _model_path = "../openvino.genai/tests/module_genai/cpp/test_models/Qwen2.5-VL-3B-Instruct/INT4/openvino_text_embeddings_model.xml";
        _model_path_bin = "../openvino.genai/tests/module_genai/cpp/test_models/Qwen2.5-VL-3B-Instruct/INT4/openvino_text_embeddings_model.bin";
        _model = core.read_model(_model_path);
    }
    std::vector<ov::Tensor> get_input() override {
        std::vector<ov::Tensor> inputs;
        ov::Shape input_shape = {1, 16};
        ov::element::Type input_type = ov::element::i64;
        ov::Tensor input_tensor(input_type, input_shape);
        int64_t *input_data = input_tensor.data<int64_t>();
        for (size_t i = 0; i < input_tensor.get_size(); ++i)
        {
            input_data[i] = i + 1000;
        }
        inputs.push_back(input_tensor);
        return inputs;
    }
};

TestModel::PTR TestModel::create(const TestModelType &model_type, ov::Core &core)
{
    if (model_type == TestModelType::VAE_DECODER)
    {
        return std::make_shared<VaeDecoderTestModel>(core);
    }
    else if (model_type == TestModelType::TRANSFORMER)
    {
        return std::make_shared<TransformerTestModel>(core);
    }
    else if (model_type == TestModelType::QWEN2_5_VL_TEXT_EMB_MODEL)
    {
        return std::make_shared<QWEN2_5_VL_TEXT_EMB_TestModel>(core);
    }
    else
    {
        throw std::runtime_error("Unsupported model type");
    }
}