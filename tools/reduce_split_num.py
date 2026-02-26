from __future__ import annotations
from pathlib import Path
import sys
import re
import numpy as np
import openvino as ov

def _load_layered_paths(ir_dir: Path, layers_per_group: int) -> tuple[Path, Path, list[Path]]:
    prefix = f"wan_dit_layered_lpg{layers_per_group}"
    preprocess = ir_dir / f"{prefix}_preprocess.xml"
    postprocess = ir_dir / f"{prefix}_postprocess.xml"
    block_group_files = list(ir_dir.glob(f"{prefix}_block_group_*_l*_n*.xml"))
    if not block_group_files:
        raise FileNotFoundError(f"No block group IRs found with prefix {prefix} in {ir_dir}")

    def _group_index(path: Path) -> int:
        match = re.search(r"_block_group_(\d+)_l", path.name)
        if not match:
            return 1_000_000
        return int(match.group(1))

    block_group_files.sort(key=_group_index)
    return preprocess, postprocess, block_group_files

def _replace_node_consumers(node, new_source_output):
        # Prefer Output.replace if available in this OV build.
        try:
            node.output(0).replace(new_source_output)
            return
        except Exception:
            print("Error: Catch exception when using replace, fallback to replace_source_output.")
            pass

def _merge_2_model(model_a: ov.Model, model_b: ov.Model) -> ov.Model:
    output_a = model_a.get_results()[0].input_value(0)
    print(f"Model A output: {output_a}, shape: {output_a.partial_shape}")

    model_a_inputs = model_a.get_parameters()
    model_b_inputs = model_b.get_parameters()
    print(f"Model A inputs: {len(model_a_inputs)}")
    print(f"Model B inputs: {len(model_b_inputs)}")
    for b_input_idx in range(len(model_b_inputs)):
        print(f"  replace Model B input {b_input_idx}: {model_b_inputs[b_input_idx].friendly_name}, shape: {model_b_inputs[b_input_idx].partial_shape}")
        if model_b_inputs[b_input_idx].friendly_name == "hidden_states":
            # 将 B 的该输入节点替换为 A 的输出
            _replace_node_consumers(model_b_inputs[b_input_idx], output_a)
        else:
            assert model_b_inputs[b_input_idx].friendly_name == model_a_inputs[b_input_idx].friendly_name, f"Unexpected input name: {model_b_inputs[b_input_idx].friendly_name} vs {model_a_inputs[b_input_idx].friendly_name}"
            _replace_node_consumers(model_b_inputs[b_input_idx], model_a_inputs[b_input_idx].output(0))

    merged_model = ov.Model([model_b.output(0)], model_a_inputs, 'MergedModel')
    return merged_model

def _merge_sub_group_xmls(group_xmls: list[Path], output_dir: Path, group_index: int, save_path: Path) -> Path:
    new_xml = save_path / f"wan_dit_layered_lpg1_block_group_{group_index}_l{group_index}_n{group_index}.xml"
    core = ov.Core()
    models = []
    for xml_path in group_xmls:
        if not xml_path.exists():
            raise FileNotFoundError(f"Missing XML file: {xml_path}")
        print(f"  - {xml_path.name}")
        cur_model = core.read_model(str(xml_path))
        models.append(cur_model)
    assert len(group_xmls) >= 2, "Expected at least 2 XML files to merge"
    first_model = models[0]
    for model in models[1:]:
        first_model = _merge_2_model(first_model, model)

    ov.serialize(first_model, str(new_xml.with_suffix(".xml")), str(new_xml.with_suffix(".bin")))    
    print(f"    Merged into {new_xml}")

def main() -> int:
    base_dir = Path(__file__).resolve().parent
    ir_dir = base_dir / "transformer_splitted"
    save_path = base_dir / "transformer_merged"
    layers_per_group = 1
    preprocess_xml, postprocess_xml, block_group_xmls = _load_layered_paths(
        ir_dir, layers_per_group
    )
    for path in [preprocess_xml, postprocess_xml, *block_group_xmls]:
        if not path.exists():
            raise FileNotFoundError(f"Missing IR file: {path}")
    # if no exists, create the save_path directory
    if not save_path.exists():
        save_path.mkdir(parents=True)
    
    # # 如果对应的bin文件不存在，则删除对应的xml文件
    # for xml_path in block_group_xmls:
    #     bin_path = xml_path.with_suffix(".bin")
    #     if not bin_path.exists():
    #         print(f"Warning: Missing bin file for {xml_path.name}, deleting {xml_path.name}")
    #         xml_path.unlink()

    print(f"block_group_xmls XML: {len(block_group_xmls)}")
    # block_group_xmls 分成3个一组
    new_block_group_xmls = []
    sub_group = []
    merge_count = 3
    for i in range(len(block_group_xmls)):
        if (i % merge_count) == 0 and i != 0:
            new_block_group_xmls.append(sub_group)
            sub_group = []
        sub_group.append(block_group_xmls[i])
    if sub_group:
        new_block_group_xmls.append(sub_group)
    
    for idx, group in enumerate(new_block_group_xmls):
        print(f"-- Group {idx}:")
        _merge_sub_group_xmls(group, ir_dir, idx, save_path)
        
    print(f"Done.")
    return 0
        


if __name__ == "__main__":
    raise SystemExit(main())