/*
 * SCPI CPUFreq Interface driver
 *
 * It provides necessary ops to arm_big_little cpufreq driver.
 *
 * Copyright (C) 2015 ARM Ltd.
 * Sudeep Holla <sudeep.holla@arm.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * This program is distributed "as is" WITHOUT ANY WARRANTY of any
 * kind, whether express or implied; without even the implied warranty
 * of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 */

#define pr_fmt(fmt) KBUILD_MODNAME ": " fmt

#include <linux/cpufreq.h>
#include <linux/module.h>
#include <linux/platform_device.h>
#include <linux/pm_opp.h>
#include <linux/scpi_protocol.h>
#include <linux/types.h>

#include "arm_big_little.h"

static struct scpi_ops *scpi_ops;

static int scpi_init_opp_table(struct device *cpu_dev)
{
	u8 domain = topology_physical_package_id(cpu_dev->id);
	struct scpi_dvfs_info *info;
	struct scpi_opp *opp;
	int idx, ret = 0;

	if ((dev_pm_opp_get_opp_count(cpu_dev)) > 0)
		return 0;
	info = scpi_ops->dvfs_get_info(domain);
	if (IS_ERR(info))
		return PTR_ERR(info);

	opp = info->opps;
	if (!opp)
		return -EIO;

	for (idx = 0; idx < info->count; idx++, opp++) {
		ret = dev_pm_opp_add(cpu_dev, opp->freq, opp->m_volt * 1000);
		if (ret) {
			dev_warn(cpu_dev, "failed to add opp %uHz %umV\n",
				 opp->freq, opp->m_volt);
			return ret;
		}
	}
	return ret;
}

static int scpi_get_transition_latency(struct device *cpu_dev)
{
	u8 domain = topology_physical_package_id(cpu_dev->id);
	struct scpi_dvfs_info *info;

	info = scpi_ops->dvfs_get_info(domain);
	if (IS_ERR(info))
		return PTR_ERR(info);

	return info->latency;
}

static struct cpufreq_arm_bL_ops scpi_cpufreq_ops = {
	.name	= "scpi",
	.get_transition_latency = scpi_get_transition_latency,
	.init_opp_table = scpi_init_opp_table,
};

static int scpi_cpufreq_probe(struct platform_device *pdev)
{
	scpi_ops = get_scpi_ops();
	if (!scpi_ops)
		return -EIO;

	return bL_cpufreq_register(&scpi_cpufreq_ops);
}

static int scpi_cpufreq_remove(struct platform_device *pdev)
{
	bL_cpufreq_unregister(&scpi_cpufreq_ops);
	return 0;
}

static struct platform_driver scpi_cpufreq_platdrv = {
	.driver = {
		.name	= "scpi-cpufreq",
		.owner	= THIS_MODULE,
	},
	.probe		= scpi_cpufreq_probe,
	.remove		= scpi_cpufreq_remove,
};
module_platform_driver(scpi_cpufreq_platdrv);

MODULE_LICENSE("GPL");
