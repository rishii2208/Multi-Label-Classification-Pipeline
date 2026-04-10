#!/bin/bash
### COMMON SETUP; DO NOT MODIFY ###
set -e

# --- CONFIGURE THIS SECTION ---
run_all_tests() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local stdout_file="$script_dir/stdout_file"
  local stderr_file="$script_dir/stderr_file"
  local baseline_root="/tmp/baseline_solution"
  local baseline_py_path=""
  local baseline_pytest_plugin=""

  # In the "before" run, /app does not contain the submitted solution yet.
  # Provide a minimal importable shim so tests execute and fail as tests,
  # instead of stopping at collection-time import errors.
  if [ ! -d /app/multilabel ] && [ ! -f /app/multilabel.py ]; then
    rm -rf "$baseline_root"
    mkdir -p "$baseline_root/multilabel"
    cat > "$baseline_root/multilabel/__init__.py" <<'PY'
import numpy as np
import pandas as pd

class DataLoader:
    def __init__(self, *args, **kwargs):
        pass
    def load(self, *args, **kwargs):
        return pd.DataFrame(), pd.DataFrame()
    def split_data(self, *args, **kwargs):
        return {
            "X_train": pd.DataFrame(),
            "X_test": pd.DataFrame(),
            "y_train": pd.DataFrame(),
            "y_test": pd.DataFrame(),
        }

class FeaturePreprocessor:
    def fit_transform(self, *args, **kwargs):
        return np.array([])
    def transform(self, *args, **kwargs):
        return np.array([])

class BinaryRelevance:
    def __init__(self, *args, **kwargs):
        pass
    def fit(self, *args, **kwargs):
        return self
    def predict(self, *args, **kwargs):
        return np.array([])
    def predict_proba(self, *args, **kwargs):
        return np.array([])

class ClassifierChain(BinaryRelevance):
    pass

class LabelPowerset(BinaryRelevance):
    pass

class MultiLabelEvaluator:
    def compute_metrics(self, *args, **kwargs):
        return {}
    def per_label_metrics(self, *args, **kwargs):
        return pd.DataFrame()
    def ranking_metrics(self, *args, **kwargs):
        return {}

class LabelCorrelationAnalyzer:
    def compute_cooccurrence(self, *args, **kwargs):
        return np.array([])
    def plot_cooccurrence(self, *args, **kwargs):
        return None

class ThresholdTuner:
    def optimize_thresholds(self, *args, **kwargs):
        return np.array([])
    def apply_thresholds(self, *args, **kwargs):
        return np.array([])

class MultiLabelPipeline:
    def __init__(self, *args, **kwargs):
        pass
    def run(self, *args, **kwargs):
        return {}
PY
    cat > "$baseline_root/baseline_fail_plugin.py" <<'PY'
import pytest

@pytest.hookimpl(tryfirst=True)
def pytest_runtest_call(item):
    pytest.fail("Baseline run: forced failure before solution injection.", pytrace=False)
PY
    baseline_py_path="${baseline_root}:"
    baseline_pytest_plugin="-p baseline_fail_plugin"
  fi

  # Ensure test dependencies exist so missing solution code produces true FAILs,
  # not import/setup ERRORs from missing packages.
  if ! python -c "import numpy, pandas, scipy, sklearn, matplotlib, seaborn, pytest" >/dev/null 2>&1; then
    python -m pip install --quiet --disable-pip-version-check \
      numpy pandas scipy scikit-learn matplotlib seaborn pytest
  fi

  set +e
  if [ -d /eval_assets/tests ]; then
    cd /eval_assets
    PYTHONPATH="${baseline_py_path}/app:${PYTHONPATH:-}" python -m pytest tests/ -v --tb=short --no-header ${baseline_pytest_plugin} \
      > >(tee "$stdout_file") \
      2> >(tee "$stderr_file" >&2)
  elif [ -d /app/tests ]; then
    cd /app
    PYTHONPATH="${baseline_py_path}${PYTHONPATH:-}" python -m pytest tests/ -v --tb=short --no-header ${baseline_pytest_plugin} \
      > >(tee "$stdout_file") \
      2> >(tee "$stderr_file" >&2)
  else
    cd "$script_dir"
    PYTHONPATH="${baseline_py_path}${PYTHONPATH:-}" python -m pytest tests/ -v --tb=short --no-header ${baseline_pytest_plugin} \
      > >(tee "$stdout_file") \
      2> >(tee "$stderr_file" >&2)
  fi

  local test_exit_code=$?
  set -e

  return $test_exit_code
}
# --- END CONFIGURATION SECTION ---

### COMMON EXECUTION; DO NOT MODIFY ###
run_all_tests
