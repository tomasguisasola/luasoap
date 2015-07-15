<wsdl:definitions ...>
 
  ...
 
  <wsdl:binding ...>
    <wsoap12:binding style="rpc|document" ?
                     transport="xs:anyURI"
                     wsdl:required="xs:boolean" ? />
    <wsdl:operation ...>
      <wsoap12:operation soapAction="xs:anyURI" ?
                         soapActionRequired="xs:boolean" ?
                         style="rpc|document" ?
                         wsdl:required="xs:boolean" ? /> ?
      <wsdl:input>
        <wsoap12:body parts="wsoap12:tParts" ?
                      use="literal|encoded" ?
                      encodingStyle="xs:anyURI" ?
                      namespace="xs:anyURI" ?
                      wsdl:required="xs:boolean" ? />
        <wsoap12:header message="xs:QName"
                        part="xs:NMTOKEN"
                        use="literal|encoded"
                        encodingStyle="xs:anyURI" ?
                        namespace="xs:anyURI" ?
                        wsdl:required="xs:boolean" ? >
          <wsoap12:headerfault message="xs:QName"
                               part="xs:NMTOKEN"
                               use="literal|encoded"
                               encodingStyle="xs:anyURI" ?
                               namespace="xs:anyURI" ?
                               wsdl:required="xs:boolean" ? /> *
        </wsoap12:header> *
      </wsdl:input> ?
      <wsdl:output>
        <!-- Same as wsdl:input -->
      </wsdl:output> ?
      <wsdl:fault>
        <wsoap12:fault name="xs:NMTOKEN"
                       use="literal | encoded"
                       encodingStyle="xs:anyURI" ?
                       namespace="xs:anyURI" ?
                       wsdl:required="xs:boolean" ?/>
      </wsdl:fault> *
    </wsdl:operation> *
  </wsdl:binding> *
 
  <wsdl:service ...>
    <wsdl:port ...>
      <wsoap12:address location="xs:anyURI"
                       wsdl:required="xs:boolean" ? />
    </wsdl:port> *
  </wsdl:service> *
 
</wsdl:definitions>
