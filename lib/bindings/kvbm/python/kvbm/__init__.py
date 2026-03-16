# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: Apache-2.0

# flake8: noqa
import logging

logger = logging.getLogger(__name__)

# nixl needs to be loaded before any other imports to ensure that the nixl shared object is available for the KVBM core.
try:
    import nixl
    import nixl._api as nixl_api
    import nixl._bindings as nixl_bindings
except ImportError as e:
    raise ImportError(
        "NIXL Python bindings must be installed to use this module. Please install NIXL, ex: 'pip install nixl'."
    ) from e

logger.info(f"Loaded nixl API module: {nixl._api}")

from kvbm._core import BlockManager as BlockManager
from kvbm._core import KvbmLeader as KvbmLeader
from kvbm._core import KvbmWorker as KvbmWorker
