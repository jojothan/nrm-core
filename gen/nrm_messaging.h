/*******************************************************************************
 * Copyright 2019 UChicago Argonne, LLC.
 * (c.f. AUTHORS, LICENSE)
 *
 * SPDX-License-Identifier: BSD-3-Clause
*******************************************************************************/
#define NRM_START_FORMAT "{\"tag\":\"start\",\"container_uuid\": \"%s\",\"application_uuid\": \"%s\"}"
#define NRM_EXIT_FORMAT "{\"tag\":\"exit\",\"application_uuid\": \"%s\"}"
#define NRM_PERFORMANCE_FORMAT "{\"tag\":\"performance\",\"container_uuid\": \"%s\",\"application_uuid\": \"%s\",\"payload\": \"%d\"}"
#define NRM_PROGRESS_FORMAT "{\"tag\":\"progress\",\"application_uuid\": \"%s\",\"payload\": \"%d\"}"
#define NRM_PHASECONTEXT_FORMAT "{\"tag\":\"phasecontext\",\"cpu\": \"%d\",\"startcompute\": \"%d\",\"endcompute\": \"%d\",\"startbarrier\": \"%d\",\"endbarrier\": \"%d\"}"