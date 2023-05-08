#!/usr/bin/env bash
#  vim:ts=4:sts=4:sw=4:et
#
#  Author: Hari Sekhon
#  Date: 2022-08-17 16:45:49 +0100 (Wed, 17 Aug 2022)
#
#  https://github.com/HariSekhon/DevOps-Bash-tools
#
#  License: see accompanying Hari Sekhon LICENSE file
#
#  If you're using my code you're welcome to connect with me on LinkedIn and optionally send me feedback to help steer this or other code I publish
#
#  https://www.linkedin.com/in/HariSekhon
#

set -euo pipefail
[ -n "${DEBUG:-}" ] && set -x
srcdir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1090,SC1091
. "$srcdir/../lib/utils.sh"

# shellcheck disable=SC2034,SC2154
usage_description="
Install Octopus Deploy CLI
"

# used by usage() in lib/utils.sh
# shellcheck disable=SC2034
usage_args=""

help_usage "$@"

#min_args 1 "$@"

version="${1:-9.0.0}"

export PATH+=':'~/bin

export OS_DARWIN=osx
export ARCH_X86_64=x64

"$srcdir/../packages/install_binary.sh" "https://download.octopusdeploy.com/octopus-tools/$version/OctopusTools.$version.{os}-{arch}.tar.gz" octo

# mkdir -pv ~/.bash.autocomplete.d/
#octo install-autocomplete --shell bash --dryRun > ~/.bash.autocomplete.d/octo.sh
#
# gets this error:
#
#    Octopus CLI, version 9.0.0
#
#    DRY RUN
#    Installing auto-complete scripts for Bash
#    Installing scripts in /Users/hari/.bashrc
#    Updating profile at /Users/hari/.bashrc
#    Preview of script changes:
#
#    System.IndexOutOfRangeException: Index was outside the bounds of the array.
#       at Serilog.Parsing.MessageTemplateParser.ParsePropertyToken(Int32 startAt, String messageTemplate, Int32& next)
#       at Serilog.Parsing.MessageTemplateParser.Tokenize(String messageTemplate)+MoveNext()
#       at System.Collections.Generic.LargeArrayBuilder`1.AddRange(IEnumerable`1 items)
#       at System.Collections.Generic.EnumerableHelpers.ToArray[T](IEnumerable`1 source)
#       at Serilog.Events.MessageTemplate..ctor(String text, IEnumerable`1 tokens)
#       at Serilog.Parsing.MessageTemplateParser.Parse(String messageTemplate)
#       at Serilog.Core.Pipeline.MessageTemplateCache.Parse(String messageTemplate)
#       at Serilog.Parameters.MessageTemplateProcessor.Process(String messageTemplate, Object[] messageTemplateParameters, MessageTemplate& parsedTemplate, IEnumerable`1& properties)
#       at Serilog.Core.Logger.Write(LogEventLevel level, Exception exception, String messageTemplate, Object[] propertyValues)
#       at Serilog.Core.Logger.Information(Exception exception, String messageTemplate, Object[] propertyValues)
#       at Serilog.Core.Logger.Information(String messageTemplate, Object[] propertyValues)
#       at Octopus.CommandLine.CommandOutputProvider.Information(String template, Object[] propertyValues)
#       at Octopus.CommandLine.ShellCompletion.ShellCompletionInstaller.Install(Boolean dryRun)
#       at Octopus.CommandLine.Commands.InstallAutoCompleteCommand.Execute(String[] commandLineArguments)
#       at Octopus.Cli.CliProgram.Run(String[] args)
#    Exit code: -3
