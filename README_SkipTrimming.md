# AutDeNovo Skip Trimming & Single-End Edition

This document describes the new features added to `AutDeNovo_exp_skiptrim.sh`, which extends the original AutDeNovo pipeline with skip trimming and single-end read support.

## New Features

### 1. Skip Trimming (`SkipTrimming=yes`)

Allows you to bypass the trimming step entirely while maintaining compatibility with downstream processing steps.

**How it works:**
- Copies raw input files to expected trimmed file names (`*_val_1.fq.gz`, `*_val_2.fq.gz`)
- Downstream steps process the raw reads as if they were trimmed
- Useful when reads are already high quality or pre-trimmed

**Usage:**
```bash
./AutDeNovo_exp_skiptrim.sh \
  Name=Sample1 \
  OutputFolder=/path/to/output \
  Fwd=/path/to/forward.fq.gz \
  Rev=/path/to/reverse.fq.gz \
  SkipTrimming=yes \
  BLASTdb=/path/to/blast/db \
  [other parameters...]
```

### 2. Single-End Read Support (`SingleEnd=yes`)

Processes forward-only reads without requiring reverse reads.

**How it works:**
- Automatically detected when only `Fwd=` is provided (no `Rev=`)
- Can be explicitly set with `SingleEnd=yes`
- Supports both trimmed and skip-trimmed modes
- Modified downstream scripts handle single-end data appropriately

**Usage (auto-detection):**
```bash
./AutDeNovo_exp_skiptrim.sh \
  Name=Sample1 \
  OutputFolder=/path/to/output \
  Fwd=/path/to/forward.fq.gz \
  BLASTdb=/path/to/blast/db \
  [other parameters...]
```

**Usage (explicit):**
```bash
./AutDeNovo_exp_skiptrim.sh \
  Name=Sample1 \
  OutputFolder=/path/to/output \
  Fwd=/path/to/forward.fq.gz \
  SingleEnd=yes \
  BLASTdb=/path/to/blast/db \
  [other parameters...]
```

### 3. Combined Usage

You can combine both features for maximum flexibility:

```bash
# Single-end reads without trimming
./AutDeNovo_exp_skiptrim.sh \
  Name=Sample1 \
  OutputFolder=/path/to/output \
  Fwd=/path/to/forward.fq.gz \
  SkipTrimming=yes \
  SingleEnd=yes \
  BLASTdb=/path/to/blast/db \
  [other parameters...]
```

## Technical Details

### Data Type Detection

The script now recognizes additional data types:
- `ILL_SE` - Single-end Illumina only
- `ILL_SE_ONT` - Single-end Illumina + ONT
- `ILL_SE_PB` - Single-end Illumina + PacBio  
- `ILL_SE_ONT_PB` - Single-end Illumina + ONT + PacBio

### Modified Scripts

The following downstream scripts have been updated to handle single-end data:
- `FullPipeline_exp/genomesize.sh` - Modified jellyfish commands for single-end
- `FullPipeline_exp/denovo.sh` - Added SPAdes single-end assembly support
- `FullPipeline_exp/mapping.sh` - Updated BWA commands for single-end
- `FullPipeline_exp/kraken.sh` - Added single-end decontamination support

### File Naming

When skip trimming is enabled:
- `{name}_1.fq.gz` → `{name}_1_val_1.fq.gz` (forward read)
- `{name}_2.fq.gz` → `{name}_2_val_2.fq.gz` (reverse read, paired-end only)

For single-end reads, only the `*_val_1.fq.gz` file is created.

## Validation and Error Handling

- Auto-detects single-end mode when reverse read is not provided
- Validates trimmer selection (atria, fastp, trimgalore)
- Provides clear error messages for missing required parameters
- Maintains backward compatibility with original parameter sets

## Examples

### Example 1: Skip trimming for paired-end reads
```bash
./AutDeNovo_exp_skiptrim.sh \
  Name=HighQuality \
  OutputFolder=/results/hq_sample \
  Fwd=/data/hq_R1.fq.gz \
  Rev=/data/hq_R2.fq.gz \
  SkipTrimming=yes \
  BLASTdb=/dbs/nt \
  threads=16
```

### Example 2: Single-end reads with trimming
```bash
./AutDeNovo_exp_skiptrim.sh \
  Name=SingleEnd \
  OutputFolder=/results/se_sample \
  Fwd=/data/se_reads.fq.gz \
  Trimmer=trimgalore \
  BaseQuality=25 \
  MinReadLen=100 \
  BLASTdb=/dbs/nt
```

### Example 3: Single-end with ONT data, no trimming
```bash
./AutDeNovo_exp_skiptrim.sh \
  Name=Hybrid \
  OutputFolder=/results/hybrid \
  Fwd=/data/illumina.fq.gz \
  ONT=/data/ont_reads \
  SkipTrimming=yes \
  BLASTdb=/dbs/nt
```

## Compatibility

This extended version maintains full backward compatibility with the original `AutDeNovo_exp.sh`. All existing parameter combinations will work exactly as before.