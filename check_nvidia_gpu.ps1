#################################################################################
# Script:       check_nvidia_gpu
# Author:       Michael Geschwinder (Maerkischer-Kreis)
# Description:  Plugin for Nagios to check NVIDIA GPUs
#
# History:
# 20190410      Created plugin
#
#
##################################################################################################################
$help="check_nvidia_gpu (c) 2018 Michael Geschwinder published under GPL license
Usage: check_nvidia_gpu.ps1 checktype warn crit"



##########################################################
# Nagios exit codes
##########################################################
$STATE_OK=0              # define the exit code if status is OK
$STATE_WARNING=1         # define the exit code if status is Warning
$STATE_CRITICAL=2        # define the exit code if status is Critical
$STATE_UNKNOWN=3         # define the exit code if status is Unknown


##########################################################
# Enable Debug permanently (NOT FOR PRODUCTION!)
##########################################################
$DEBUG=0

##########################################################
# Debug output function
##########################################################
function debug_out ($dbgtext){
        if ($DEBUG -eq "1" ){
                $datestring=$(Get-Date -UFormat +%d%m%Y-%H:%M:%S)
                write-host $datestring DEBUG: $dbgtext
        }
}


  if ($args.count -eq 1) {
    $checktype = $args[0]
    $warn = 999
    $crit = 999
  }

  elseif ($args.count -eq 3) {
    $checktype = $args[0]
    $warn = $args[1]
    $crit = $args[2]
  }

  else{
    write-host "UNKNOWN: Falsche Anzahl Parameter!"
    write-host $help
    exit $STATE_UNKNOWN
}


$namespace = "ROOT\cimv2\NV"
$gpuclass = "Gpu"
$tempclass = "ThermalProbe"
$coolerclass = "Cooler"




switch ( $checktype )
{
    info
    {
        $wmiresult=Get-WmiObject -Class $gpuclass -Namespace $namespace
        $model=$wmiresult.name
        $arch=$wmiresult.archName
        $cores=$wmiresult.coreCount
        $dev=$wmiresult.deviceInfo
        $memsize=$wmiresult.memorySizePhysical

        $outtext="NVIDIA $model`nArchitecture: $arch`nCores: $cores`nDevice: $dev`nMemory: $memsize MB"
    }


    temp
    {
        $wmiresult=Get-WmiObject -Class $tempclass -Namespace $namespace
        $temp=$wmiresult.temperature

        if ( $temp -gt $crit ) {
            $outtext="CRITICAL Temperature is $temp C | temp=$temp;$warn;$crit"
            $result=$STATE_CRITICAL

        } elseif ( $temp -gt $warn) {
            $outtext="WARNING Temperature is $temp C | temp=$temp;$warn;$crit"
            $result=$STATE_WARNING
        } else {
            $outtext="OK Temperature is $temp C | temp=$temp;$warn;$crit"
            $result=$STATE_OK
        }
    }

    fan
    {
        $wmiresult=Get-WmiObject -Class $coolerclass -Namespace $namespace
        $coolerrate=$wmiresult.percentCoolerRate
        $speed=$wmiresult.fanSpeed
        $minspeed=$wmiresult.minSpeed
        $maxspeed=$wmiresult.maxSpeed

        if ( $coolerrate -gt $crit ) {
            $outtext="CRITICAL Fan is at $coolerrate % | fanperc=$coolerrate%;$warn;$crit fanspeed=$speed;;;$minspeed;$maxspeed"
            $result=$STATE_CRITICAL

        } elseif ( $coolerrate -gt $warn) {
            $outtext="WARNING Fan is at $coolerrate % | fanperc=$coolerrate%;$warn;$crit fanspeed=$speed;;;$minspeed;$maxspeed"
            $result=$STATE_WARNING
        } else {
            $outtext="OK Fan is at $coolerrate % | fanperc=$coolerrate%;$warn;$crit fanspeed=$speed;;;$minspeed;$maxspeed"
            $result=$STATE_OK
        }

    }

    gpuusage
    {
        $wmiresult=Get-WmiObject -Class $gpuclass -Namespace $namespace
        $gpuusage=$wmiresult.percentGpuUsage
        if ( $gpuusage -gt $crit ) {
            $outtext="CRITICAL GPUUsage is at $gpuusage % | gpuusage=$gpuusage%;$warn;$crit;0;100"
            $result=$STATE_CRITICAL

        } elseif ( $gpuusage -gt $warn) {
            $outtext="WARNING GPUUsage is at $gpuusage % | gpuusage=$gpuusage%;$warn;$crit;0;100"
            $result=$STATE_WARNING
        } else {
            $outtext="OK GPUUsage is at $gpuusage % | gpuusage=$gpuusage%;$warn;$crit;0;100"
            $result=$STATE_OK
        }
    }
    
    memoryusage
    {
        $wmiresult=Get-WmiObject -Class $gpuclass -Namespace $namespace
        $memusage=$wmiresult.percentGpuMemoryUsage
        if ( $memusage -gt $crit ) {
            $outtext="CRITICAL Memory Usage is at $memusage % | gpuusage=$memusage%;$warn;$crit;0;100"
            $result=$STATE_CRITICAL

        } elseif ( $gpuusage -gt $warn) {
            $outtext="WARNING Memory Usage is at $memusage % | gpuusage=$memusage%;$warn;$crit;0;100"
            $result=$STATE_WARNING
        } else {
            $outtext="OK Memory Usage is at $memusage % | gpuusage=$memusage%;$warn;$crit;0;100"
            $result=$STATE_OK
        }
    }


    default
    {
        write-host "Select checktype!"
        $result=$STATE_UNKNOWN
    }

}




Write-Host $outtext
exit $result
