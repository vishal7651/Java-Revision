import java.io.IOException;

class ChargingException extends Exception{
    ChargingException(String m){
        super(m);
    }
}

public class TryCatchFinallyThrowThrows {

    public static void charging(int q) throws ArithmeticException, IOException, ChargingException{
       try {
         if(q<10){
         throw new ChargingException("Charging is below 10");
        }else{
            System.out.println("Charging is above 10");
        }
       } catch (ChargingException e) {
        System.out.println(e.getMessage());
       }
       finally{
        System.out.println("Finally Block ALways Called ");
       }
       
        }
    
    public static void main(String[] args) {
        try{
            charging(-9);
        }catch(ChargingException | IOException | ArithmeticException e3){
            System.out.println(e3);
        }
        
    }
    
}
