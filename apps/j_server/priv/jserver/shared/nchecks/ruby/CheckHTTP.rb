# Sysmo NMS Network Management and Monitoring solution (http://www.sysmo.io)
#
# Copyright (c) 2012-2015 Sebastien Serre <ssbx@sysmo.io>
#
# This file is part of Sysmo NMS.
#
# Sysmo NMS is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# Sysmo NMS is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with Foobar.  If not, see <http://www.gnu.org/licenses/>.
require 'java'
java_import 'io.sysmo.nchecks.Reply'
java_import 'io.sysmo.nchecks.Status'

require 'net/http'

def check(query) # query is io.sysmo.nchecks.Query

  reply  = Reply.new()

  # Extract arguments from java Query -> Argument {asString|asInteger}
  uristr  = query.get("uri").asString()

  begin
    uri  = URI(uristr)
    http = Net::HTTP.new(uri.host, uri.port)
  rescue Exception => ex
    reply.setStatus(Reply::STATUS_ERROR)
    reply.setReply("#{ex.class} #{ex.message}")
    return reply
  end

  # check MUST reply within 15 seconds
  http.read_timeout = 5
  http.open_timeout = 5
  repstr = nil

  begin
    start  = Time.now

    if uri.path.eql? ""
      path = "/"
    else
      path = uri.path
    end

    response = http.get(path)
    finish = Time.now
    diff   = (finish - start) * 1000

    # will raise an error if code is not 2**
    value = response.value()

    reply.setStatus(Status::OK)
    reply.setReply("HTTP Get successfull response")
    reply.putPerformance("ReplyDuration", diff)

  rescue Net::HTTPServerException => ex
    reply.setStatus(Status::CRITICAL)
    reply.setReply(ex.message())

  rescue Timeout::Error => ex
    reply.setStatus(Status::CRITICAL)
    reply.setReply(ex.message)

  rescue Errno::ECONNREFUSED => ex
    reply.setStatus(Status::CRITICAL)
    reply.setReply("Connection refused")

  rescue Exception => ex
    reply.setStatus(Status::ERROR)
    reply.setReply("#{ex.class} #{ex.message}")

  end

  return reply

end